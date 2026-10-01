// Package job is a scheduled systemd unit or workflow, as configured by the
// nix module.
package job

import (
	"encoding/json"
	"fmt"
	"os"
	"time"

	"github.com/robfig/cron/v3"
)

type Job struct {
	Name string `json:"name"`
	Cron string `json:"cron"`
	Unit string `json:"unit,omitempty"`
	// User runs Unit as a user unit of this user, when set.
	User string `json:"user,omitempty"`
	// Doctor is the App ID hosting the job-doctor agent, which explains why
	// Unit failed, when set.
	Doctor string `json:"doctor,omitempty"`

	// Workflow, in place of Unit, is a workflow of App ID AppID to run with
	// Input.
	Workflow string `json:"workflow,omitempty"`
	AppID    string `json:"appId,omitempty"`
	Input    string `json:"input,omitempty"`
}

// Load reads a JSON list of jobs, and checks each runs one thing on a cron
// spec that parses.
func Load(path string) ([]Job, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var jobs []Job
	if err := json.Unmarshal(b, &jobs); err != nil {
		return nil, err
	}
	for _, j := range jobs {
		if _, err := cron.ParseStandard(j.Cron); err != nil {
			return nil, fmt.Errorf("job %s: %w", j.Name, err)
		}
		if (j.Unit == "") == (j.Workflow == "") {
			return nil, fmt.Errorf("job %s: needs exactly one of unit and workflow", j.Name)
		}
		if j.Workflow != "" && j.AppID == "" {
			return nil, fmt.Errorf("job %s: workflow needs an appId", j.Name)
		}
	}
	return jobs, nil
}

// NextRun is the first cron time after now.
func (j Job) NextRun(now time.Time) (time.Time, error) {
	s, err := cron.ParseStandard(j.Cron)
	if err != nil {
		return time.Time{}, err
	}
	// Cron specs without CRON_TZ follow the zone of the time given, and the
	// workflow clock is UTC, so use this machine's zone.
	return s.Next(now.Local()), nil
}
