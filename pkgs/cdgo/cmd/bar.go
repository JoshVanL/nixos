package cmd

import (
	"fmt"
	"os/exec"
	"strings"
	"time"

	"github.com/spf13/cobra"

	"github.com/joshvanl/cdgo/internal/job"
)

var barInterval time.Duration

// barCmd owns the dwm status bar (root window WM_NAME), composing the job
// segment with the datetime that xpropdate used to render on its own.
var barCmd = &cobra.Command{
	Use:    "bar",
	Short:  "Status bar loop: render job counts and datetime into WM_NAME",
	Hidden: true,
	RunE: func(cmd *cobra.Command, args []string) error {
		for {
			line := time.Now().Format("Monday 2006/01/02 15:04")
			if seg := jobSegment(); seg != "" {
				line = seg + " " + line
			}
			if out, err := exec.Command("xsetroot", "-name", line).CombinedOutput(); err != nil {
				return fmt.Errorf("xsetroot: %v: %s", err, out)
			}
			time.Sleep(barInterval)
		}
	},
}

func jobSegment() string {
	jobs, err := job.List()
	if err != nil {
		return ""
	}
	var running, ok, bad int
	for _, j := range jobs {
		switch {
		case j.Status == job.StatusRunning:
			running++
		case j.Acked:
		case j.Status == job.StatusSucceeded:
			ok++
		default:
			bad++
		}
	}
	if running+ok+bad == 0 {
		return ""
	}
	var parts []string
	if running > 0 {
		parts = append(parts, fmt.Sprintf("%d run", running))
	}
	if ok > 0 {
		parts = append(parts, fmt.Sprintf("%d ok", ok))
	}
	if bad > 0 {
		parts = append(parts, fmt.Sprintf("%d fail", bad))
	}
	return "[jobs " + strings.Join(parts, ", ") + "]"
}

func init() {
	barCmd.Flags().DurationVar(&barInterval, "interval", 10*time.Second, "poll interval")
	rootCmd.AddCommand(barCmd)
}
