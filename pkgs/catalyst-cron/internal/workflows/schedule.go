package workflows

import (
	"errors"
	"fmt"
	"log"
	"time"

	"github.com/dapr/durabletask-go/task"
	"github.com/dapr/durabletask-go/workflow"

	"github.com/joshvanl/catalyst-cron/internal/job"
)

// RunNowEvent, raised on a Schedule instance, starts its next run straight
// away.
const RunNowEvent = "run-now"

// RunInput is the input of a single run of a job.
type RunInput struct {
	job.Job
	ScheduledFor time.Time `json:"scheduledFor"`
}

// ScheduleInput is the input of Schedule. Its JSON is a superset of the bare
// job that ScheduleV1 takes.
type ScheduleInput struct {
	job.Job
	Last *LastRun `json:"last,omitempty"`
}

// LastRun is how the previous run of a job went.
type LastRun struct {
	StartedAt time.Time `json:"startedAt"`
	Success   bool      `json:"success"`
	Duration  string    `json:"duration"`
	Instance  string    `json:"instance"`
}

// status is state followed by how the last run went.
func (in ScheduleInput) status(state string) string {
	l := in.Last
	switch {
	case l == nil:
		return state
	case l.Success:
		return fmt.Sprintf("%s, last run %s succeeded in %s",
			state, l.StartedAt.Format(time.RFC3339), l.Duration)
	default:
		return fmt.Sprintf("%s, last run %s failed after %s (%s)",
			state, l.StartedAt.Format(time.RFC3339), l.Duration, l.Instance)
	}
}

// ScheduleV2 is ScheduleV1, plus RunNowEvent to run ahead of the cron time,
// and the last run's result in the custom status.
func ScheduleV2(ctx *workflow.WorkflowContext) (any, error) {
	var in ScheduleInput
	if err := ctx.GetInput(&in); err != nil {
		return nil, err
	}

	now := ctx.CurrentTimeUTC()
	next, err := in.NextRun(now)
	if err != nil {
		return nil, err
	}
	ctx.SetCustomStatus(in.status("next run " + next.Format(time.RFC3339)))

	// The wait times out at the cron time, unless a run is asked for first.
	switch err := ctx.WaitForExternalEvent(RunNowEvent, next.Sub(now)).Await(nil); {
	case err == nil:
		next = ctx.CurrentTimeUTC().Local()
	case !errors.Is(err, task.ErrTaskCanceled):
		return nil, err
	}

	// Started can be well after next, when this machine was off at the cron time.
	started := ctx.CurrentTimeUTC().Local()
	ctx.SetCustomStatus(in.status("running since " + started.Format(time.RFC3339)))
	id := ctx.ID() + "-" + next.UTC().Format("20060102T150405Z")
	err = ctx.CallChildWorkflow(Run,
		workflow.WithChildWorkflowInstanceID(id),
		workflow.WithChildWorkflowInput(RunInput{Job: in.Job, ScheduledFor: next}),
	).Await(nil)
	if err != nil && !ctx.IsReplaying() {
		// A failed run must not end the schedule.
		log.Printf("%s: run failed: %v", ctx.ID(), err)
	}
	in.Last = &LastRun{
		StartedAt: started,
		Success:   err == nil,
		Duration:  ctx.CurrentTimeUTC().Sub(started).Round(time.Second).String(),
		Instance:  id,
	}

	// Keeping unprocessed events means a run asked for during this one runs next.
	ctx.ContinueAsNew(in, workflow.WithKeepUnprocessedEvents())
	return nil, nil
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
