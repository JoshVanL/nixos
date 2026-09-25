package cmd

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/spf13/cobra"

	"github.com/joshvanl/cdgo/internal/job"
	"github.com/joshvanl/cdgo/internal/workspace"
)

var rmForce bool

var rmCmd = &cobra.Command{
	Use:               "rm <name>",
	Short:             "Remove a workspace (refuses dirty repos without --force)",
	Args:              cobra.ExactArgs(1),
	ValidArgsFunction: completeWorkspaceNames,
	RunE: func(cmd *cobra.Command, args []string) error {
		name := args[0]
		if err := workspace.ValidName(name); err != nil {
			return err
		}
		dir := workspace.Dir(name)

		// Only ever delete strictly inside the workspace root, and never the
		// workspace this shell is standing in.
		real, err := filepath.EvalSymlinks(dir)
		if err != nil {
			return fmt.Errorf("no such workspace: %s", name)
		}
		rootReal, err := filepath.EvalSymlinks(workspace.Root())
		if err != nil {
			return err
		}
		if !strings.HasPrefix(real, rootReal+string(filepath.Separator)) {
			return fmt.Errorf("refusing to remove %s: outside workspace root", real)
		}
		if cw := os.Getenv("CDGO_WORKSPACE"); cw == dir {
			return fmt.Errorf("refusing to remove the workspace you are currently inside")
		}
		if j, err := job.Load(dir); err == nil && j.Status == job.StatusRunning && job.UnitActive(j.Unit) {
			return fmt.Errorf("job %q is still running; stop it first: cdgo job stop %s", j.Name, j.Name)
		}

		info, err := workspace.Inspect(dir, false)
		if err != nil {
			return err
		}
		if info.Dirty() && !rmForce {
			return fmt.Errorf("workspace %s has unsaved work (%s); use --force to delete anyway", name, info.DirtyDetail())
		}
		if err := os.RemoveAll(real); err != nil {
			return err
		}
		fmt.Fprintf(os.Stderr, ">> removed %s\n", real)
		return nil
	},
}

func init() {
	rmCmd.Flags().BoolVarP(&rmForce, "force", "f", false, "delete even with uncommitted/unpushed work")
	rootCmd.AddCommand(rmCmd)
}
