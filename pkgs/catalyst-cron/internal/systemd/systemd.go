// Package systemd starts a unit, waits for it, and reports how it went.
package systemd

import (
	"context"
	"fmt"
	"os/exec"
	"strings"
	"time"
)

// Result is how a unit run ended, as reported by systemd.
type Result struct {
	Unit       string    `json:"unit"`
	Result     string    `json:"result"`
	ExitStatus string    `json:"exitStatus"`
	StartedAt  time.Time `json:"startedAt"`
	FinishedAt time.Time `json:"finishedAt"`
	Duration   string    `json:"duration"`
	Log        []string  `json:"log"`
}

// Run starts unit and waits for it to finish. With user set, unit is that
// user's user unit. A unit that does not succeed returns an error holding
// the same report, with the tail of its journal.
func Run(ctx context.Context, unit, user string) (Result, error) {
	var scope []string
	match := "_SYSTEMD_UNIT=" + unit
	if user != "" {
		scope = []string{"--user", "--machine=" + user + "@.host"}
		match = "_SYSTEMD_USER_UNIT=" + unit
	}

	res := Result{Unit: unit, StartedAt: time.Now().UTC()}
	// Exit code is ignored here, as systemd's own Result below says more.
	_ = exec.CommandContext(ctx, "systemctl", append(scope, "start", "--wait", unit)...).Run()
	res.FinishedAt = time.Now().UTC()
	res.Duration = res.FinishedAt.Sub(res.StartedAt).Round(time.Second).String()

	out, err := exec.CommandContext(ctx, "systemctl", append(scope, "show", unit,
		"-p", "Result", "-p", "ExecMainStatus")...).Output()
	if err != nil {
		return res, fmt.Errorf("systemctl show %s: %w", unit, err)
	}
	for _, line := range strings.Split(strings.TrimSpace(string(out)), "\n") {
		k, v, _ := strings.Cut(line, "=")
		switch k {
		case "Result":
			res.Result = v
		case "ExecMainStatus":
			res.ExitStatus = v
		}
	}

	// systemd clears InvocationID once a oneshot goes inactive, so match the
	// run by unit and start time.
	out, _ = exec.CommandContext(ctx, "journalctl", "--no-pager", "-o", "cat", "-n", "20",
		"--since", fmt.Sprintf("@%d", res.StartedAt.Unix()), match).Output()
	if s := strings.TrimSpace(string(out)); s != "" {
		res.Log = strings.Split(s, "\n")
	}

	if res.Result != "success" {
		return res, fmt.Errorf("%s: result=%s exit=%s after %s\n%s",
			unit, res.Result, res.ExitStatus, res.Duration, strings.Join(res.Log, "\n"))
	}
	return res, nil
}
