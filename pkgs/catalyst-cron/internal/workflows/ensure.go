package workflows

import (
	"context"
	"encoding/json"
	"log"

	"github.com/dapr/durabletask-go/workflow"

	"github.com/joshvanl/catalyst-cron/internal/job"
)

// Ensure leaves a running Schedule instance with the same job alone,
// otherwise replaces it so schedule changes take effect.
func Ensure(ctx context.Context, wf *workflow.Client, id string, j job.Job) error {
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

	if _, err := wf.ScheduleWorkflow(ctx, Schedule, workflow.WithInstanceID(id), workflow.WithInput(j)); err != nil {
		return err
	}
	log.Printf("%s: scheduled %q", id, j.Cron)
	return nil
}
