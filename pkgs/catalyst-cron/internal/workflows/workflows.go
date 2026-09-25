// Package workflows holds the versioned Dapr workflows that schedule jobs.
//
// Workflows are registered under a canonical name with one implementation
// per version. New instances run the latest version, and each instance
// replays with the version recorded in its history. Schedule picks up a new
// version at its next ContinueAsNew. To change a workflow's behaviour, add
// a new version (e.g. ScheduleV2) marked latest, and keep the old ones
// registered until no instance still uses them.
package workflows

import (
	"github.com/dapr/durabletask-go/workflow"
)

const (
	// Canonical workflow names, which instances are started with.
	Schedule = "Schedule"
	Run      = "Run"
)

// Register adds every workflow version and activity to r.
func Register(r *workflow.Registry) error {
	for _, v := range []struct {
		canonical, name string
		latest          bool
		wf              workflow.Workflow
	}{
		{Schedule, "ScheduleV1", true, ScheduleV1},
		{Run, "RunV1", true, RunV1},
	} {
		if err := r.AddVersionedWorkflowN(v.canonical, v.name, v.latest, v.wf); err != nil {
			return err
		}
	}
	return r.AddActivityN("RunUnit", RunUnit)
}
