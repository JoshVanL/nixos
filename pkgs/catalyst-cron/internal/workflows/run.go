package workflows

import (
	"fmt"
	"log"
	"os/exec"
	"strings"
	"time"

	"github.com/dapr/durabletask-go/workflow"

	"github.com/joshvanl/catalyst-cron/internal/job"
	"github.com/joshvanl/catalyst-cron/internal/systemd"
)

// RunUnit runs the job's systemd unit.
func RunUnit(ctx workflow.ActivityContext) (any, error) {
	var j job.Job
	if err := ctx.GetInput(&j); err != nil {
		return nil, err
	}
	res, err := systemd.Run(ctx.Context(), j.Unit, j.User)
	if err != nil {
		return nil, err
	}
	return res, nil
}

// WorkflowResult is what a workflow job's workflow returns.
type WorkflowResult struct {
	Summary string `json:"summary"`
	// Notify asks for Summary as a desktop notification.
	Notify bool `json:"notify"`
}

// Notification is the input of Notify.
type Notification struct {
	Title string `json:"title"`
	Body  string `json:"body"`
}

// DoctorWorkflow is the workflow of the job-doctor Dapr agent.
const DoctorWorkflow = "dapr.agents.job-doctor.workflow"

// RunV2 is a single run of a job: its systemd unit, retried on failure, or a
// workflow on another App ID. Failures, and results that ask for one, become
// desktop notifications. A failed unit with a Doctor gets diagnosed by the
// job-doctor agent, as a child workflow.
func RunV2(ctx *workflow.WorkflowContext) (any, error) {
	if !ctx.IsReplaying() {
		log.Printf("Running workflow %s", ctx.ID())
	}

	var in RunInput
	if err := ctx.GetInput(&in); err != nil {
		return nil, err
	}

	if in.Workflow != "" {
		var res WorkflowResult
		err := ctx.CallChildWorkflow(in.Workflow,
			workflow.WithChildWorkflowAppID(in.AppID),
			workflow.WithChildWorkflowInstanceID(ctx.ID()+"-"+in.Workflow),
			workflow.WithChildWorkflowInput(in.Input),
		).Await(&res)
		switch {
		case err != nil:
			notify(ctx, in.Name+" failed", FirstLine(err.Error()))
			return nil, err
		case res.Notify:
			notify(ctx, in.Name, res.Summary)
		}
		return res, nil
	}

	started := ctx.CurrentTimeUTC()
	var res systemd.Result
	err := ctx.CallActivity(RunUnitV1,
		workflow.WithActivityInput(in.Job),
		workflow.WithActivityRetryPolicy(&workflow.RetryPolicy{
			MaxAttempts:          3,
			InitialRetryInterval: time.Minute,
			BackoffCoefficient:   2,
		}),
	).Await(&res)
	if err == nil {
		if !ctx.IsReplaying() {
			log.Printf("Completed workflow %s", ctx.ID())
		}
		return res, nil
	}

	if !ctx.IsReplaying() {
		log.Printf("Workflow %s failed: %v", ctx.ID(), err)
	}
	if in.Doctor == "" {
		notify(ctx, in.Name+" failed", FirstLine(err.Error()))
		return nil, err
	}

	scope := "system unit"
	if in.User != "" {
		scope = "user unit of " + in.User
	}
	task := fmt.Sprintf("The scheduled job %s runs the %s %s. A run that started at %s "+
		"failed three attempts in a row. The last attempt reported:\n\n%s",
		in.Name, scope, in.Unit, started.Local().Format(time.DateTime), err)
	var answer struct {
		Content string `json:"content"`
	}
	if derr := ctx.CallChildWorkflow(DoctorWorkflow,
		workflow.WithChildWorkflowAppID(in.Doctor),
		workflow.WithChildWorkflowInstanceID(ctx.ID()+"-doctor"),
		workflow.WithChildWorkflowInput(map[string]string{"task": task}),
	).Await(&answer); derr != nil {
		notify(ctx, in.Name+" failed", FirstLine(err.Error())+" (job-doctor failed: "+FirstLine(derr.Error())+")")
		return nil, err
	}
	notify(ctx, in.Name+" failed", answer.Content)
	// The diagnosis first, so it is what catalyst-cron ls shows.
	return nil, fmt.Errorf("%s\n\n%w", answer.Content, err)
}

// notify sends a desktop notification, logging rather than failing when it
// cannot.
func notify(ctx *workflow.WorkflowContext, title, body string) {
	err := ctx.CallActivity(NotifyV1, workflow.WithActivityInput(Notification{title, body})).Await(nil)
	if err != nil && !ctx.IsReplaying() {
		log.Printf("Workflow %s: notify: %v", ctx.ID(), err)
	}
}

// Notify returns the activity that shows a Notification on user's desktop,
// or does nothing when user is empty.
func Notify(user string) workflow.Activity {
	return func(ctx workflow.ActivityContext) (any, error) {
		if user == "" {
			return nil, nil
		}
		var n Notification
		if err := ctx.GetInput(&n); err != nil {
			return nil, err
		}
		// The user manager's PATH does not have it, so pass an absolute path.
		bin, err := exec.LookPath("notify-send")
		if err != nil {
			return nil, err
		}
		out, err := exec.CommandContext(ctx.Context(), "systemd-run", "--user", "--machine="+user+"@.host",
			"--quiet", "--collect", "--", bin, "--app-name=catalyst-cron", n.Title, n.Body).CombinedOutput()
		if err != nil {
			return nil, fmt.Errorf("%w: %s", err, out)
		}
		return nil, nil
	}
}

// FirstLine is the first line of a child task's error, without the SDK's
// prefix.
func FirstLine(s string) string {
	s = strings.TrimPrefix(s, "task failed with an error: ")
	s, _, _ = strings.Cut(s, "\n")
	return s
}
