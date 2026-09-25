// Package job manages cdgo background jobs: headless claude runs inside the
// sandbox, supervised by transient systemd user units. All durable state
// lives in <workspace>/.cdgo/ (job.json, goal.md, job.log, result/), which
// survives the root rollback; the transient units do not, so `running`
// entries with no live unit are reconciled to `interrupted`.
package job

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/joshvanl/cdgo/internal/workspace"
)

const (
	StatusRunning     = "running"
	StatusSucceeded   = "succeeded"
	StatusFailed      = "failed"
	StatusStopped     = "stopped"
	StatusInterrupted = "interrupted"
)

type Job struct {
	Name          string     `json:"name"`
	Workspace     string     `json:"workspace"`
	Unit          string     `json:"unit"`
	Template      string     `json:"template,omitempty"`
	Status        string     `json:"status"`
	StartedAt     time.Time  `json:"started_at"`
	FinishedAt    *time.Time `json:"finished_at"`
	ExitCode      string     `json:"exit_code,omitempty"`
	ServiceResult string     `json:"service_result,omitempty"`
	StopRequested bool       `json:"stop_requested"`
	Acked         bool       `json:"acked"`
	MaxTurns      int        `json:"max_turns,omitempty"`
}

func UnitName(name string) string { return "cdgo-job-" + name + ".service" }

func Path(ws string) string { return filepath.Join(ws, ".cdgo", "job.json") }

func GoalPath(ws string) string { return filepath.Join(ws, ".cdgo", "goal.md") }

func LogPath(ws string) string { return filepath.Join(ws, ".cdgo", "job.log") }

func ResultDir(ws string) string { return filepath.Join(ws, ".cdgo", "result") }

func Load(ws string) (*Job, error) {
	b, err := os.ReadFile(Path(ws))
	if err != nil {
		return nil, err
	}
	var j Job
	if err := json.Unmarshal(b, &j); err != nil {
		return nil, err
	}
	return &j, nil
}

func (j *Job) Save() error {
	return workspace.WriteJSONAtomic(Path(j.Workspace), j)
}

func (j *Job) Runtime() time.Duration {
	end := time.Now()
	if j.FinishedAt != nil {
		end = *j.FinishedAt
	}
	if j.StartedAt.IsZero() {
		return 0
	}
	return end.Sub(j.StartedAt).Round(time.Second)
}

// UnitActive reports whether the job's systemd user unit is active.
func UnitActive(unit string) bool {
	return exec.Command("systemctl", "--user", "is-active", "--quiet", unit).Run() == nil
}

// Reconcile flips a stale `running` job whose unit is gone (reboot, user
// manager crash) to `interrupted`.
func (j *Job) Reconcile() error {
	if j.Status != StatusRunning || UnitActive(j.Unit) {
		return nil
	}
	now := time.Now()
	j.Status = StatusInterrupted
	j.FinishedAt = &now
	return j.Save()
}

// List loads and reconciles every job across all workspaces, newest first.
func List() ([]*Job, error) {
	entries, err := os.ReadDir(workspace.Root())
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil
		}
		return nil, err
	}
	var jobs []*Job
	for _, e := range entries {
		if !e.IsDir() || strings.HasPrefix(e.Name(), ".") {
			continue
		}
		ws := filepath.Join(workspace.Root(), e.Name())
		j, err := Load(ws)
		if err != nil {
			continue
		}
		if err := j.Reconcile(); err != nil {
			fmt.Fprintf(os.Stderr, ">> warning: reconcile %s: %v\n", j.Name, err)
		}
		jobs = append(jobs, j)
	}
	sort.Slice(jobs, func(a, b int) bool {
		return jobs[a].StartedAt.After(jobs[b].StartedAt)
	})
	return jobs, nil
}

// GoalSummary returns the first non-empty line of the goal, truncated.
func GoalSummary(ws string, max int) string {
	b, err := os.ReadFile(GoalPath(ws))
	if err != nil {
		return "-"
	}
	for _, line := range strings.Split(string(b), "\n") {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		if len(line) > max {
			return line[:max-3] + "..."
		}
		return line
	}
	return "-"
}
