// catalyst-cron runs systemd units, or workflows of other Catalyst App IDs, on
// a cron schedule, using Dapr workflows hosted on Diagrid Catalyst in place of
// systemd timers.
package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"os"
	"os/signal"
	"slices"
	"strings"
	"syscall"
	"text/tabwriter"
	"time"

	"github.com/dapr/durabletask-go/api"
	"github.com/dapr/durabletask-go/workflow"
	"github.com/dapr/go-sdk/client"
	"github.com/spf13/cobra"

	"github.com/joshvanl/catalyst-cron/internal/job"
	"github.com/joshvanl/catalyst-cron/internal/workflows"
)

func main() {
	root := &cobra.Command{
		Use:          "catalyst-cron",
		Short:        "Run systemd units on a cron schedule using Dapr workflows on Diagrid Catalyst",
		SilenceUsage: true,
	}
	config := root.PersistentFlags().String("config", "/etc/catalyst-cron/jobs.json", "path to JSON list of jobs")
	envFile := root.PersistentFlags().String("env-file", "/etc/catalyst-cron/env",
		"systemd EnvironmentFile holding the Catalyst App ID's DAPR_* variables, for run and list")
	root.AddCommand(serveCmd(config), runCmd(config, envFile), listCmd(config, envFile))
	if err := root.Execute(); err != nil {
		os.Exit(1)
	}
}

func serveCmd(config *string) *cobra.Command {
	var notifyUser string
	cmd := &cobra.Command{
		Use:   "serve",
		Short: "Run the workflow worker and keep every job scheduled",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, _ []string) error {
			jobs, err := job.Load(*config)
			if err != nil {
				return err
			}

			ctx, cancel := signal.NotifyContext(cmd.Context(), os.Interrupt, syscall.SIGTERM)
			defer cancel()

			wf, err := client.NewWorkflowClient()
			if err != nil {
				return err
			}

			r := workflow.NewRegistry()
			if err := workflows.Register(r, notifyUser); err != nil {
				return err
			}
			if err := wf.StartWorker(ctx, r); err != nil {
				return err
			}

			for _, j := range jobs {
				id, err := instanceID(j.Name)
				if err != nil {
					return err
				}
				if err := workflows.Ensure(ctx, wf, id, j); err != nil {
					return fmt.Errorf("job %s: %w", j.Name, err)
				}
			}

			<-ctx.Done()
			return nil
		},
	}
	cmd.Flags().StringVar(&notifyUser, "notify-user", "", "user to show failures and results to as desktop notifications")
	return cmd
}

func runCmd(config, envFile *string) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "run <job>",
		Short: "Run a job now, ahead of its next cron time",
		Args:  cobra.ExactArgs(1),
		ValidArgsFunction: func(_ *cobra.Command, args []string, _ string) ([]string, cobra.ShellCompDirective) {
			jobs, err := job.Load(*config)
			if err != nil || len(args) > 0 {
				return nil, cobra.ShellCompDirectiveNoFileComp
			}
			var names []string
			for _, j := range jobs {
				names = append(names, j.Name)
			}
			return names, cobra.ShellCompDirectiveNoFileComp
		},
	}

	cmd.RunE = func(cmd *cobra.Command, args []string) error {
		jobs, err := job.Load(*config)
		if err != nil {
			return err
		}
		if !slices.ContainsFunc(jobs, func(j job.Job) bool { return j.Name == args[0] }) {
			return fmt.Errorf("unknown job %q", args[0])
		}
		wf, err := dial(*envFile)
		if err != nil {
			return err
		}
		id, err := instanceID(args[0])
		if err != nil {
			return err
		}
		if err := wf.RaiseEvent(cmd.Context(), id, workflows.RunNowEvent); err != nil {
			return err
		}
		log.Printf("%s: run requested, see its custom status for how it went", id)
		return nil
	}
	return cmd
}

func listCmd(config, envFile *string) *cobra.Command {
	var output string
	cmd := &cobra.Command{
		Use:     "list",
		Aliases: []string{"ls"},
		Short:   "List jobs with the status of their schedule on Catalyst",
		Args:    cobra.NoArgs,
		RunE: func(cmd *cobra.Command, _ []string) error {
			jobs, err := job.Load(*config)
			if err != nil {
				return err
			}
			wf, err := dial(*envFile)
			if err != nil {
				return err
			}

			wide := output == "wide"
			w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
			if wide {
				fmt.Fprintln(w, "JOB\tSCHEDULE\tRUNS\tNEXT\tLAST\tSTATUS\tRESULT")
			} else {
				fmt.Fprintln(w, "JOB\tNEXT\tLAST\tSTATUS")
			}
			for _, j := range jobs {
				id, err := instanceID(j.Name)
				if err != nil {
					return err
				}
				md, err := wf.FetchWorkflowMetadata(cmd.Context(), id, workflow.WithFetchPayloads(true))
				next, last, state := schedule(j, md, err)
				if !wide {
					fmt.Fprintf(w, "%s\t%s\t%s\t%s\n", j.Name, next, last, state)
					continue
				}
				_, spec, _ := strings.Cut(j.Cron, " ")
				if !strings.HasPrefix(j.Cron, "CRON_TZ=") {
					spec = j.Cron
				}
				runs := j.Unit
				if j.Workflow != "" {
					runs = fmt.Sprintf("%s/%s(%s)", j.AppID, j.Workflow, j.Input)
				}
				fmt.Fprintf(w, "%s\t%s\t%s\t%s\t%s\t%s\t%s\n", j.Name, spec, runs, next, last, state,
					truncate(lastResult(cmd.Context(), wf, j, md), 80))
			}
			return w.Flush()
		},
	}
	cmd.Flags().StringVarP(&output, "output", "o", "", "output format: wide adds the schedule, what runs, and the last result")
	return cmd
}

// timeFormat is short and local: the year and zone are rarely news.
const timeFormat = "Mon 02 Jan 15:04"

// schedule is when a job runs next, when it last ran, and how that went or
// what its Schedule instance is doing.
func schedule(j job.Job, md *workflow.WorkflowMetadata, err error) (next, last, state string) {
	switch {
	case errors.Is(err, api.ErrInstanceNotFound):
		return "-", "-", "not scheduled"
	case err != nil:
		return "-", "-", "error: " + err.Error()
	case md.RuntimeStatus != workflow.StatusRunning:
		state = md.String()
		if msg, _, _ := strings.Cut(md.FailureDetails.GetErrorMessage(), "\n"); msg != "" {
			state += ": " + msg
		}
		return "-", "-", state
	}

	next, last, state = "-", "-", "-"
	if n, err := j.NextRun(time.Now()); err == nil {
		next = n.Local().Format(timeFormat)
	}
	var in workflows.ScheduleInput
	if json.Unmarshal([]byte(md.Input.GetValue()), &in) == nil && in.Last != nil {
		last = in.Last.StartedAt.Local().Format(timeFormat)
		state = "failed " + in.Last.Duration
		if in.Last.Success {
			state = "ok " + in.Last.Duration
		}
	}
	if strings.HasPrefix(md.CustomStatus.GetValue(), "running since") {
		state = "running"
	}
	return next, last, state
}

func truncate(s string, n int) string {
	if r := []rune(s); len(r) > n {
		return string(r[:n-1]) + "…"
	}
	return s
}

// lastResult is what the last run of a Schedule instance reported: why it
// failed, with the job-doctor's diagnosis first for a unit, or a workflow
// job's summary.
func lastResult(ctx context.Context, wf *workflow.Client, j job.Job, md *workflow.WorkflowMetadata) string {
	var in workflows.ScheduleInput
	if md == nil || json.Unmarshal([]byte(md.Input.GetValue()), &in) != nil || in.Last == nil ||
		(j.Unit != "" && in.Last.Success) {
		return ""
	}

	md, err := wf.FetchWorkflowMetadata(ctx, in.Last.Instance, workflow.WithFetchPayloads(true))
	switch {
	case errors.Is(err, api.ErrInstanceNotFound):
		return ""
	case err != nil:
		return "error: " + err.Error()
	case md.RuntimeStatus == workflow.StatusRunning:
		return "running"
	case md.FailureDetails.GetErrorMessage() != "":
		return workflows.FirstLine(md.FailureDetails.GetErrorMessage())
	}
	var res workflows.WorkflowResult
	_ = json.Unmarshal([]byte(md.Output.GetValue()), &res)
	return workflows.FirstLine(res.Summary)
}

// dial connects to Catalyst using the service's EnvironmentFile, for commands
// run outside the service.
func dial(envFile string) (*workflow.Client, error) {
	if err := loadEnv(envFile); err != nil {
		return nil, err
	}
	// The SDK logs connecting to stdout, which would mix into list's output.
	client.SetLogger(nil)
	return client.NewWorkflowClient()
}

// instanceID is the Schedule instance of the named job on this machine.
func instanceID(name string) (string, error) {
	host, err := os.Hostname()
	if err != nil {
		return "", err
	}
	return host + "-" + name, nil
}

// loadEnv sets the variables of a systemd EnvironmentFile, as the service
// gets them.
func loadEnv(path string) error {
	b, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	for _, line := range strings.Split(string(b), "\n") {
		k, v, ok := strings.Cut(strings.TrimSpace(line), "=")
		if !ok || strings.HasPrefix(k, "#") {
			continue
		}
		if err := os.Setenv(k, strings.Trim(v, `"'`)); err != nil {
			return err
		}
	}
	return nil
}
