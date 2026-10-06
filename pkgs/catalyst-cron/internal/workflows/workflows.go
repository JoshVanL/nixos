// Package workflows holds the versioned Dapr workflows that schedule jobs.
//
// Workflows are registered under a canonical name with one implementation
// per version. New instances run the latest version, and each instance
// replays with the version recorded in its history. Ensure replaces Schedule
// instances on an older version when catalyst-cron starts, and Run picks up
// a new version with the next run. To change a workflow's behaviour, add a
// new version (e.g. ScheduleV3) marked latest, and keep the old ones
// registered until no instance still uses them.
//
// Activities carry their version in their name (e.g. RunUnitV1), as the SDK
// does not version them. To change an activity's input, output or behaviour,
// register it under a new name, call that from a new workflow version, and
// keep the old name registered alongside the workflow versions that call it.
package workflows

import (
	"github.com/dapr/durabletask-go/workflow"
)

const (
	// Canonical workflow names, which instances are started with.
	Schedule = "Schedule"
	Run      = "Run"

	// latestSchedule is the version new Schedule instances run.
	latestSchedule = "ScheduleV2"

	// Activity names, versioned.
	RunUnitV1 = "RunUnitV1"
	NotifyV1  = "NotifyV1"
)

// Register adds every workflow version and activity to r. Notify sends
// desktop notifications to notifyUser.
func Register(r *workflow.Registry, notifyUser string) error {
	for _, v := range []struct {
		canonical, name string
		latest          bool
		wf              workflow.Workflow
	}{
		{Schedule, "ScheduleV1", false, ScheduleV1},
		{Schedule, latestSchedule, true, ScheduleV2},
		{Run, "RunV2", true, RunV2},
	} {
		if err := r.AddVersionedWorkflowN(v.canonical, v.name, v.latest, v.wf); err != nil {
			return err
		}
	}
	for name, a := range map[string]workflow.Activity{
		RunUnitV1: RunUnit,
		NotifyV1:  Notify(notifyUser),
	} {
		if err := r.AddActivityN(name, a); err != nil {
			return err
		}
	}
	return nil
}
