// Package job is a scheduled systemd unit, as configured by the nix module.
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
	Unit string `json:"unit"`
	// User runs Unit as a user unit of this user, when set.
	User string `json:"user,omitempty"`
}

// Load reads a JSON list of jobs and checks each cron spec parses.
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
