package cmd

import (
	"fmt"
	"os"
	"time"

	"github.com/spf13/cobra"

	"github.com/joshvanl/cdgo/internal/job"
	"github.com/joshvanl/cdgo/internal/workspace"
)

var (
	gcMaxAgeDays int
	gcDryRun     bool
)

var gcCmd = &cobra.Command{
	Use:   "gc",
	Short: "Delete old clean workspaces (dirty ones are only reported, never deleted)",
	RunE: func(cmd *cobra.Command, args []string) error {
		maxAge := time.Duration(gcMaxAgeDays) * 24 * time.Hour
		infos, err := workspace.List(false)
		if err != nil {
			return err
		}
		for _, i := range infos {
			age := time.Since(i.LastUsed())
			if age < maxAge {
				continue
			}
			days := int(age.Hours() / 24)
			if j, err := job.Load(i.Dir); err == nil && j.Status == job.StatusRunning && job.UnitActive(j.Unit) {
				fmt.Fprintf(os.Stderr, ">> keeping %s: job still running\n", i.Name)
				continue
			}
			if i.Dirty() {
				fmt.Fprintf(os.Stderr, ">> keeping %s: unused for %dd but dirty (%s)\n", i.Name, days, i.DirtyDetail())
				continue
			}
			if gcDryRun {
				fmt.Fprintf(os.Stderr, ">> would remove %s: unused for %dd, clean\n", i.Name, days)
				continue
			}
			if err := os.RemoveAll(i.Dir); err != nil {
				fmt.Fprintf(os.Stderr, ">> warning: remove %s: %v\n", i.Name, err)
				continue
			}
			fmt.Fprintf(os.Stderr, ">> removed %s: unused for %dd, clean\n", i.Name, days)
		}
		return nil
	},
}

func init() {
	gcCmd.Flags().IntVar(&gcMaxAgeDays, "max-age-days", 14, "delete clean workspaces unused for this many days")
	gcCmd.Flags().BoolVar(&gcDryRun, "dry-run", false, "only report what would be deleted")
	rootCmd.AddCommand(gcCmd)
}
