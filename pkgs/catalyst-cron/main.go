// catalyst-cron runs systemd units on a cron schedule, using one Dapr
// workflow per job hosted on Diagrid Catalyst in place of systemd timers.
package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"os/exec"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/dapr/durabletask-go/workflow"
	"github.com/dapr/go-sdk/client"
	"github.com/robfig/cron/v3"
)

type Job struct {
	Name string `json:"name"`
	Cron string `json:"cron"`
	Unit string `json:"unit"`
	// User runs Unit as a user unit of this user, when set.
	User string `json:"user,omitempty"`
}

func main() {
	configPath := flag.String("config", "", "path to JSON list of jobs")
	flag.Parse()

	b, err := os.ReadFile(*configPath)
	if err != nil {
		log.Fatal(err)
	}
	var jobs []Job
	if err := json.Unmarshal(b, &jobs); err != nil {
		log.Fatal(err)
	}
	for _, j := range jobs {
		if _, err := cron.ParseStandard(j.Cron); err != nil {
			log.Fatalf("job %s: %v", j.Name, err)
		}
	}

	host, err := os.Hostname()
	if err != nil {
		log.Fatal(err)
	}

	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer cancel()

	wf, err := client.NewWorkflowClient()
	if err != nil {
		log.Fatal(err)
	}

	r := workflow.NewRegistry()
	if err := r.AddWorkflow(Schedule); err != nil {
		log.Fatal(err)
	}
	if err := r.AddWorkflow(Run); err != nil {
		log.Fatal(err)
	}
	if err := r.AddActivity(RunUnit); err != nil {
		log.Fatal(err)
	}
	if err := wf.StartWorker(ctx, r); err != nil {
		log.Fatal(err)
	}

	for _, j := range jobs {
		if err := ensure(ctx, wf, host+"-"+j.Name, j); err != nil {
			log.Fatalf("job %s: %v", j.Name, err)
		}
	}

	<-ctx.Done()
}

// ensure leaves a running instance with the same job alone, otherwise
// replaces it so schedule changes take effect.
func ensure(ctx context.Context, wf *workflow.Client, id string, j Job) error {
	want, err := json.Marshal(j)
	if err != nil {
		return err
	}

	md, err := wf.FetchWorkflowMetadata(ctx, id, workflow.WithFetchPayloads(true))
	if err == nil && md != nil {
		if md.RuntimeStatus == workflow.StatusRunning && md.Input.GetValue() == string(want) {
			log.Printf("%s: already scheduled", id)
			return nil
		}
		// Terminate fails on an already finished instance, which is fine.
		_ = wf.TerminateWorkflow(ctx, id)
		if _, err := wf.WaitForWorkflowCompletion(ctx, id); err != nil {
			return err
		}
		if err := wf.PurgeWorkflowState(ctx, id); err != nil {
			return err
		}
	}

	if _, err := wf.ScheduleWorkflow(ctx, "Schedule", workflow.WithInstanceID(id), workflow.WithInput(j)); err != nil {
		return err
	}
	log.Printf("%s: scheduled %q", id, j.Cron)
	return nil
}

// RunInput is a single run of a job.
type RunInput struct {
	Job
	ScheduledFor time.Time `json:"scheduledFor"`
}

// RunResult is how a unit run ended, as reported by systemd.
type RunResult struct {
	Unit       string    `json:"unit"`
	Result     string    `json:"result"`
	ExitStatus string    `json:"exitStatus"`
	StartedAt  time.Time `json:"startedAt"`
	FinishedAt time.Time `json:"finishedAt"`
	Duration   string    `json:"duration"`
	Log        []string  `json:"log"`
}

// Schedule waits for the next cron time, runs the job as a child workflow so
// each run is tracked as its own instance, then starts over.
func Schedule(ctx *workflow.WorkflowContext) (any, error) {
	var j Job
	if err := ctx.GetInput(&j); err != nil {
		return nil, err
	}

	now := ctx.CurrentTimeUTC()
	next, err := nextRun(j.Cron, now)
	if err != nil {
		return nil, err
	}
	ctx.SetCustomStatus("next run " + next.Format(time.RFC3339))
	if err := ctx.CreateTimer(next.Sub(now)).Await(nil); err != nil {
		return nil, err
	}

	ctx.SetCustomStatus("running since " + next.Format(time.RFC3339))
	err = ctx.CallChildWorkflow(Run,
		workflow.WithChildWorkflowInstanceID(ctx.ID()+"-"+next.UTC().Format("20060102T150405Z")),
		workflow.WithChildWorkflowInput(RunInput{Job: j, ScheduledFor: next}),
	).Await(nil)
	if err != nil && !ctx.IsReplaying() {
		// A failed run must not end the schedule.
		log.Printf("%s: run failed: %v", ctx.ID(), err)
	}

	ctx.ContinueAsNew(j)
	return nil, nil
}

func Run(ctx *workflow.WorkflowContext) (any, error) {
	var in RunInput
	if err := ctx.GetInput(&in); err != nil {
		return nil, err
	}

	var res RunResult
	err := ctx.CallActivity(RunUnit,
		workflow.WithActivityInput(in.Job),
		workflow.WithActivityRetryPolicy(&workflow.RetryPolicy{
			MaxAttempts:          3,
			InitialRetryInterval: time.Minute,
			BackoffCoefficient:   2,
		}),
	).Await(&res)
	if err != nil {
		return nil, err
	}
	return res, nil
}

// RunUnit starts the unit, waits for it to finish, and reports how it went
// with the tail of its journal. A failed unit fails the activity, with the
// same report in the error so it shows in the workflow's failure details.
func RunUnit(ctx workflow.ActivityContext) (any, error) {
	var j Job
	if err := ctx.GetInput(&j); err != nil {
		return nil, err
	}

	var scope []string
	match := "_SYSTEMD_UNIT=" + j.Unit
	if j.User != "" {
		scope = []string{"--user", "--machine=" + j.User + "@.host"}
		match = "_SYSTEMD_USER_UNIT=" + j.Unit
	}

	res := RunResult{Unit: j.Unit, StartedAt: time.Now().UTC()}
	// Exit code is ignored here, as systemd's own Result below says more.
	_ = exec.CommandContext(ctx.Context(), "systemctl", append(scope, "start", "--wait", j.Unit)...).Run()
	res.FinishedAt = time.Now().UTC()
	res.Duration = res.FinishedAt.Sub(res.StartedAt).Round(time.Second).String()

	out, err := exec.CommandContext(ctx.Context(), "systemctl", append(scope, "show", j.Unit,
		"-p", "Result", "-p", "ExecMainStatus")...).Output()
	if err != nil {
		return nil, fmt.Errorf("systemctl show %s: %w", j.Unit, err)
	}
	for _, line := range strings.Split(strings.TrimSpace(string(out)), "\n") {
		k, v, _ := strings.Cut(line, "=")
		switch k {
		case "Result":
			res.Result = v
		case "ExecMainStatus":
			res.ExitStatus = v
		}
	}

	// systemd clears InvocationID once a oneshot goes inactive, so match the
	// run by unit and start time.
	out, _ = exec.CommandContext(ctx.Context(), "journalctl", "--no-pager", "-o", "cat", "-n", "20",
		"--since", fmt.Sprintf("@%d", res.StartedAt.Unix()), match).Output()
	if s := strings.TrimSpace(string(out)); s != "" {
		res.Log = strings.Split(s, "\n")
	}

	if res.Result != "success" {
		return nil, fmt.Errorf("%s: result=%s exit=%s after %s\n%s",
			j.Unit, res.Result, res.ExitStatus, res.Duration, strings.Join(res.Log, "\n"))
	}
	return res, nil
}

func nextRun(spec string, now time.Time) (time.Time, error) {
	s, err := cron.ParseStandard(spec)
	if err != nil {
		return time.Time{}, err
	}
	// Cron specs without CRON_TZ follow the zone of the time given, and the
	// workflow clock is UTC, so use this machine's zone.
	return s.Next(now.Local()), nil
}
