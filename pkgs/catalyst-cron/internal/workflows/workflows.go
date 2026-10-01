// Package workflows holds the versioned Dapr workflows that schedule jobs.
//
// Workflows are registered under a canonical name with one implementation
// per version. New instances run the latest version, and each instance
// replays with the version recorded in its history. Ensure replaces Schedule
// instances on an older version when catalyst-cron starts, and Run picks up
// a new version with the next run. To change a workflow's behaviour, add a
// new version (e.g. ScheduleV3) marked latest, and keep the old ones
// registered until no instance still uses them.
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
		{Run, "RunV1", false, RunV1},
		{Run, "RunV2", true, RunV2},
	} {
		if err := r.AddVersionedWorkflowN(v.canonical, v.name, v.latest, v.wf); err != nil {
			return err
		}
	}
	for name, a := range map[string]workflow.Activity{
		"RunUnit": RunUnit,
		"Notify":  Notify(notifyUser),
	} {
		if err := r.AddActivityN(name, a); err != nil {
			return err
		}
	}
	return nil
}
