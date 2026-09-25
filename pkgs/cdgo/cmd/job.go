package cmd

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"syscall"
	"text/tabwriter"
	"time"

	"github.com/spf13/cobra"

	"github.com/joshvanl/cdgo/internal/config"
	"github.com/joshvanl/cdgo/internal/job"
	"github.com/joshvanl/cdgo/internal/sandbox"
	"github.com/joshvanl/cdgo/internal/workspace"
	"github.com/joshvanl/cdgo/internal/xnotify"
)

var jobCmd = &cobra.Command{
	Use:   "job",
	Short: "Long-running background claude agents in sandboxes",
}

func jobByName(name string) (*job.Job, error) {
	if err := workspace.ValidName(name); err != nil {
		return nil, err
	}
	j, err := job.Load(workspace.Dir(name))
	if err != nil {
		return nil, fmt.Errorf("no job state for %q (see `cdgo job ls`)", name)
	}
	return j, j.Reconcile()
}

// ---- cdgo job start ----

var (
	jobTemplate string
	jobGoalFile string
	jobMaxTurns int
)

var jobStartCmd = &cobra.Command{
	Use:   "start [-t template] [-f goal-file] <name> [group-or-repo...] [-- goal words...]",
	Short: "Start a background job: headless claude with a goal in a sandbox",
	Long: `Create the workspace, then launch a transient systemd user unit
(cdgo-job-<name>.service) running headless claude inside the sandbox. The
goal is composed from the template prompt (-t), then the inline goal (after
--), the goal file (-f), or stdin (when piped), then the shared finish
protocol. Watch with ` + "`cdgo job tail <name>`" + `; on completion a desktop
notification points at the result.`,
	Args:              cobra.MinimumNArgs(1),
	ValidArgsFunction: completeWorkspaceNames,
	RunE: func(cmd *cobra.Command, args []string) error {
		if os.Getenv("CDGO_SANDBOX") == "1" {
			return fmt.Errorf("cdgo job start cannot run inside a sandbox")
		}

		var goalWords []string
		if dash := cmd.ArgsLenAtDash(); dash >= 0 {
			goalWords = args[dash:]
			args = args[:dash]
		}
		if len(args) < 1 {
			return fmt.Errorf("missing job name")
		}
		name, repos := args[0], args[1:]
		if err := workspace.ValidName(name); err != nil {
			return err
		}
		if strings.ContainsAny(name, "._") || name != strings.ToLower(name) {
			return fmt.Errorf("job name %q must be lowercase [a-z0-9-] (it becomes a systemd unit name)", name)
		}

		// Compose the goal.
		var parts []string
		if jobTemplate != "" {
			tpl, ok := cfg.JobTemplates[jobTemplate]
			if !ok {
				var known []string
				for k := range cfg.JobTemplates {
					known = append(known, k)
				}
				return fmt.Errorf("unknown job template %q (known: %s)", jobTemplate, strings.Join(known, ", "))
			}
			parts = append(parts, strings.TrimSpace(tpl.Prompt))
			repos = append(repos, tpl.Groups...)
		}
		switch {
		case len(goalWords) > 0:
			parts = append(parts, strings.Join(goalWords, " "))
		case jobGoalFile != "":
			b, err := os.ReadFile(jobGoalFile)
			if err != nil {
				return err
			}
			parts = append(parts, strings.TrimSpace(string(b)))
		default:
			if fi, _ := os.Stdin.Stat(); fi != nil && fi.Mode()&os.ModeCharDevice == 0 {
				b, err := io.ReadAll(os.Stdin)
				if err != nil {
					return err
				}
				if s := strings.TrimSpace(string(b)); s != "" {
					parts = append(parts, s)
				}
			}
		}
		if len(parts) == 0 {
			return fmt.Errorf("no goal given (use -t, -f, stdin, or -- goal words)")
		}
		if cfg.JobEpilogueFile != "" {
			b, err := os.ReadFile(cfg.JobEpilogueFile)
			if err != nil {
				return err
			}
			parts = append(parts, strings.TrimSpace(string(b)))
		}

		unit := job.UnitName(name)
		if job.UnitActive(unit) {
			return fmt.Errorf("job %q is already running; watch: cdgo job tail %s, stop: cdgo job stop %s", name, name, name)
		}

		ws, err := workspace.Create(cfg, name, repos)
		if err != nil {
			return err
		}

		// Rotate state from a previous run of the same workspace.
		for _, f := range []string{job.LogPath(ws), job.Path(ws)} {
			if _, err := os.Stat(f); err == nil {
				if err := os.Rename(f, f+".1"); err != nil {
					return err
				}
			}
		}
		if err := os.WriteFile(job.GoalPath(ws), []byte(strings.Join(parts, "\n\n")+"\n"), 0o644); err != nil {
			return err
		}
		j := &job.Job{
			Name:      name,
			Workspace: ws,
			Unit:      unit,
			Template:  jobTemplate,
			Status:    job.StatusRunning,
			StartedAt: time.Now(),
			MaxTurns:  jobMaxTurns,
		}
		if err := j.Save(); err != nil {
			return err
		}

		self, err := os.Executable()
		if err != nil {
			return err
		}
		runArgs := []string{
			"--user", "--collect",
			"--unit", "cdgo-job-" + name,
			"--description", "cdgo job: " + name,
			"--property", "Type=exec",
			"--property", fmt.Sprintf("ExecStopPost=%s job finish %s", self, ws),
			"--setenv", "CDGO_CONFIG=" + os.Getenv("CDGO_CONFIG"),
			"--setenv", "PATH=" + os.Getenv("PATH"),
		}
		if cfg.JobMaxRuntime != "" {
			runArgs = append(runArgs, "--property", "RuntimeMaxSec="+cfg.JobMaxRuntime)
		}
		runArgs = append(runArgs, "--", self, "job", "run", ws)
		run := exec.Command("systemd-run", runArgs...)
		run.Stdout = os.Stderr
		run.Stderr = os.Stderr
		if err := run.Run(); err != nil {
			return fmt.Errorf("systemd-run: %w", err)
		}

		fmt.Fprintf(os.Stderr, ">> started job %q (%s)\n", name, unit)
		fmt.Fprintf(os.Stderr, ">>   goal:   %s\n", job.GoalPath(ws))
		fmt.Fprintf(os.Stderr, ">>   watch:  cdgo job tail %s\n", name)
		fmt.Fprintf(os.Stderr, ">>   stop:   cdgo job stop %s\n", name)
		return nil
	},
}

// ---- cdgo job run / finish (internal, ExecStart / ExecStopPost) ----

var jobRunCmd = &cobra.Command{
	Use:    "run <workspace-dir>",
	Hidden: true,
	Args:   cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		ws := args[0]
		j, err := job.Load(ws)
		if err != nil {
			return err
		}
		goal, err := os.ReadFile(job.GoalPath(ws))
		if err != nil {
			return err
		}

		// The canonical log lives on /keep next to the job state; redirect
		// this process (and everything exec'd over it) into it.
		logf, err := os.OpenFile(job.LogPath(ws), os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0o644)
		if err != nil {
			return err
		}
		if err := syscall.Dup3(int(logf.Fd()), 1, 0); err != nil {
			return err
		}
		if err := syscall.Dup3(int(logf.Fd()), 2, 0); err != nil {
			return err
		}

		command := []string{
			"claude-d", "-p", string(goal),
			"--output-format", "stream-json", "--verbose",
		}
		if j.MaxTurns > 0 {
			command = append(command, "--max-turns", strconv.Itoa(j.MaxTurns))
		}
		return sandbox.Exec(cfg, ws, sandbox.Options{
			SettingsOverride: cfg.JobSettingsFile,
			Command:          command,
		})
	},
}

var jobFinishCmd = &cobra.Command{
	Use:    "finish <workspace-dir>",
	Hidden: true,
	Args:   cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		j, err := job.Load(args[0])
		if err != nil {
			return err
		}
		serviceResult := os.Getenv("SERVICE_RESULT")
		switch {
		case j.StopRequested:
			j.Status = job.StatusStopped
		case serviceResult == "success":
			j.Status = job.StatusSucceeded
		default:
			j.Status = job.StatusFailed
		}
		now := time.Now()
		j.FinishedAt = &now
		j.ServiceResult = serviceResult
		j.ExitCode = os.Getenv("EXIT_STATUS")
		if err := j.Save(); err != nil {
			return err
		}

		urgency := "normal"
		if j.Status != job.StatusSucceeded {
			urgency = "critical"
		}
		xnotify.Send(urgency,
			fmt.Sprintf("cdgo job %s: %s", j.Name, j.Status),
			fmt.Sprintf("runtime: %s\nresult: cdgo job result %s\nreview: cdgo sandbox --resume %s",
				j.Runtime(), j.Name, j.Name))
		return nil
	},
}

// ---- cdgo job ls ----

var jobLsCmd = &cobra.Command{
	Use:     "ls",
	Aliases: []string{"list"},
	Short:   "List jobs and their status",
	RunE: func(cmd *cobra.Command, args []string) error {
		jobs, err := job.List()
		if err != nil {
			return err
		}
		if len(jobs) == 0 {
			fmt.Fprintln(os.Stderr, ">> no jobs")
			return nil
		}
		w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
		fmt.Fprintln(w, "NAME\tSTATUS\tRUNTIME\tSTARTED\tGOAL")
		for _, j := range jobs {
			status := j.Status
			if j.Status != job.StatusRunning && !j.Acked {
				status += "*"
			}
			fmt.Fprintf(w, "%s\t%s\t%s\t%s\t%s\n",
				j.Name, status, j.Runtime(),
				j.StartedAt.Format("02/01/2006 15:04"),
				job.GoalSummary(j.Workspace, 60))
		}
		if err := w.Flush(); err != nil {
			return err
		}
		fmt.Fprintln(os.Stderr, ">> * = unacknowledged (clear with `cdgo job ack`)")
		return nil
	},
}

// ---- cdgo job tail / log ----

type streamEvent struct {
	Type    string `json:"type"`
	Subtype string `json:"subtype"`
	Result  string `json:"result"`
	Message struct {
		Content []struct {
			Type string `json:"type"`
			Text string `json:"text"`
			Name string `json:"name"`
		} `json:"content"`
	} `json:"message"`
}

func printStreamLine(line string) {
	var ev streamEvent
	if err := json.Unmarshal([]byte(line), &ev); err != nil {
		return
	}
	switch ev.Type {
	case "assistant":
		for _, c := range ev.Message.Content {
			switch c.Type {
			case "text":
				fmt.Println(strings.TrimSpace(c.Text))
			case "tool_use":
				fmt.Printf("[tool: %s]\n", c.Name)
			}
		}
	case "result":
		fmt.Printf(">> result (%s): %s\n", ev.Subtype, strings.TrimSpace(ev.Result))
	}
}

var jobTailCmd = &cobra.Command{
	Use:               "tail <name>",
	Short:             "Follow a job's assistant output (filtered from stream-json)",
	Args:              cobra.ExactArgs(1),
	ValidArgsFunction: completeJobNames,
	RunE: func(cmd *cobra.Command, args []string) error {
		j, err := jobByName(args[0])
		if err != nil {
			return err
		}
		f, err := os.Open(job.LogPath(j.Workspace))
		if err != nil {
			return err
		}
		defer f.Close()
		r := bufio.NewReader(f)
		for {
			line, err := r.ReadString('\n')
			if line != "" {
				printStreamLine(strings.TrimRight(line, "\n"))
			}
			if err == io.EOF {
				j, jerr := job.Load(j.Workspace)
				if jerr == nil && j.Status != job.StatusRunning {
					return nil
				}
				time.Sleep(500 * time.Millisecond)
				continue
			}
			if err != nil {
				return err
			}
		}
	},
}

var jobLogCmd = &cobra.Command{
	Use:               "log <name>",
	Short:             "Print a job's raw log",
	Args:              cobra.ExactArgs(1),
	ValidArgsFunction: completeJobNames,
	RunE: func(cmd *cobra.Command, args []string) error {
		j, err := jobByName(args[0])
		if err != nil {
			return err
		}
		f, err := os.Open(job.LogPath(j.Workspace))
		if err != nil {
			return err
		}
		defer f.Close()
		_, err = io.Copy(os.Stdout, f)
		return err
	},
}

// ---- cdgo job stop / ack / result ----

var jobStopCmd = &cobra.Command{
	Use:               "stop <name>",
	Short:             "Stop a running job",
	Args:              cobra.ExactArgs(1),
	ValidArgsFunction: completeJobNames,
	RunE: func(cmd *cobra.Command, args []string) error {
		j, err := jobByName(args[0])
		if err != nil {
			return err
		}
		if j.Status != job.StatusRunning {
			return fmt.Errorf("job %q is not running (status: %s)", j.Name, j.Status)
		}
		j.StopRequested = true
		if err := j.Save(); err != nil {
			return err
		}
		out, err := exec.Command("systemctl", "--user", "stop", j.Unit).CombinedOutput()
		if err != nil {
			return fmt.Errorf("systemctl stop: %v: %s", err, out)
		}
		fmt.Fprintf(os.Stderr, ">> stopped job %q\n", j.Name)
		return nil
	},
}

var jobAckAll bool

var jobAckCmd = &cobra.Command{
	Use:               "ack [name]",
	Short:             "Acknowledge finished jobs (clears the status bar segment)",
	Args:              cobra.MaximumNArgs(1),
	ValidArgsFunction: completeJobNames,
	RunE: func(cmd *cobra.Command, args []string) error {
		var jobs []*job.Job
		if jobAckAll || len(args) == 0 {
			all, err := job.List()
			if err != nil {
				return err
			}
			jobs = all
		} else {
			j, err := jobByName(args[0])
			if err != nil {
				return err
			}
			jobs = []*job.Job{j}
		}
		for _, j := range jobs {
			if j.Status == job.StatusRunning || j.Acked {
				continue
			}
			j.Acked = true
			if err := j.Save(); err != nil {
				return err
			}
			fmt.Fprintf(os.Stderr, ">> acked %s (%s)\n", j.Name, j.Status)
		}
		return nil
	},
}

var jobResultCmd = &cobra.Command{
	Use:               "result <name>",
	Short:             "Show a job's SUMMARY.md and exported patches",
	Args:              cobra.ExactArgs(1),
	ValidArgsFunction: completeJobNames,
	RunE: func(cmd *cobra.Command, args []string) error {
		j, err := jobByName(args[0])
		if err != nil {
			return err
		}
		dir := job.ResultDir(j.Workspace)
		summary := dir + "/SUMMARY.md"
		b, err := os.ReadFile(summary)
		if err != nil {
			return fmt.Errorf("no result summary at %s (job status: %s)", summary, j.Status)
		}
		os.Stdout.Write(b)
		var patches []string
		_ = walkFiles(dir, func(path string) {
			if strings.HasSuffix(path, ".patch") {
				patches = append(patches, path)
			}
		})
		if len(patches) > 0 {
			fmt.Println("\npatches:")
			for _, p := range patches {
				fmt.Println("  " + p)
			}
		}
		return nil
	},
}

func walkFiles(dir string, fn func(path string)) error {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return err
	}
	for _, e := range entries {
		p := dir + "/" + e.Name()
		if e.IsDir() {
			_ = walkFiles(p, fn)
		} else {
			fn(p)
		}
	}
	return nil
}

func init() {
	jobStartCmd.Flags().StringVarP(&jobTemplate, "template", "t", "", "job template name from nix config")
	jobStartCmd.Flags().StringVarP(&jobGoalFile, "goal-file", "f", "", "read the goal from a file")
	jobStartCmd.Flags().IntVar(&jobMaxTurns, "max-turns", 0, "limit claude to this many turns")
	jobStartCmd.RegisterFlagCompletionFunc("template", func(cmd *cobra.Command, args []string, toComplete string) ([]string, cobra.ShellCompDirective) {
		c, err := config.Load()
		if err != nil {
			return nil, cobra.ShellCompDirectiveNoFileComp
		}
		var names []string
		for k := range c.JobTemplates {
			names = append(names, k)
		}
		return names, cobra.ShellCompDirectiveNoFileComp
	})
	jobAckCmd.Flags().BoolVar(&jobAckAll, "all", false, "acknowledge all finished jobs")
	jobCmd.AddCommand(jobStartCmd, jobRunCmd, jobFinishCmd, jobLsCmd, jobTailCmd, jobLogCmd, jobStopCmd, jobAckCmd, jobResultCmd)
	rootCmd.AddCommand(jobCmd)
}
