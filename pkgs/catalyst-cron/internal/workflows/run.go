package workflows

import (
	"time"

	"github.com/dapr/durabletask-go/workflow"

	"github.com/joshvanl/catalyst-cron/internal/job"
	"github.com/joshvanl/catalyst-cron/internal/systemd"
)

// RunV1 is a single run of a job, retrying the unit on failure.
func RunV1(ctx *workflow.WorkflowContext) (any, error) {
	var in RunInput
	if err := ctx.GetInput(&in); err != nil {
		return nil, err
	}

	var res systemd.Result
	err := ctx.CallActivity("RunUnit",
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
