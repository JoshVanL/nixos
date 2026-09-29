package workflows

import (
	"context"
	"encoding/json"
	"log"

	"github.com/dapr/durabletask-go/workflow"

	"github.com/joshvanl/catalyst-cron/internal/job"
)

// Ensure leaves a running Schedule instance with the same job and the latest
// version alone. Otherwise it replaces it, so schedule and workflow changes
// take effect, keeping how its last run went.
func Ensure(ctx context.Context, wf *workflow.Client, id string, j job.Job) error {
	in := ScheduleInput{Job: j}

	md, err := wf.FetchWorkflowMetadata(ctx, id, workflow.WithFetchPayloads(true))
	if err == nil && md != nil {
		var have ScheduleInput
		// Input that does not parse is just replaced.
		_ = json.Unmarshal([]byte(md.Input.GetValue()), &have)
		if md.RuntimeStatus == workflow.StatusRunning && md.Version.GetValue() == latestSchedule && have.Job == j {
			log.Printf("%s: already scheduled", id)
			return nil
		}
		in.Last = have.Last

		// Terminate fails on an already finished instance, which is fine.
		_ = wf.TerminateWorkflow(ctx, id)
		if _, err := wf.WaitForWorkflowCompletion(ctx, id); err != nil {
			return err
		}
		if err := wf.PurgeWorkflowState(ctx, id); err != nil {
			return err
		}
	}

	if _, err := wf.ScheduleWorkflow(ctx, Schedule, workflow.WithInstanceID(id), workflow.WithInput(in)); err != nil {
		return err
	}
	log.Printf("%s: scheduled %q", id, j.Cron)
	return nil
}
