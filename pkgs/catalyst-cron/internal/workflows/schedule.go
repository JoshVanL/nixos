package workflows

import (
	"log"
	"time"

	"github.com/dapr/durabletask-go/workflow"

	"github.com/joshvanl/catalyst-cron/internal/job"
)

// RunInput is the input of a single run of a job.
type RunInput struct {
	job.Job
	ScheduledFor time.Time `json:"scheduledFor"`
}

// ScheduleV1 waits for the next cron time, runs the job as a child workflow
// so each run is tracked as its own instance, then starts over.
func ScheduleV1(ctx *workflow.WorkflowContext) (any, error) {
	var j job.Job
	if err := ctx.GetInput(&j); err != nil {
		return nil, err
	}

	now := ctx.CurrentTimeUTC()
	next, err := j.NextRun(now)
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
