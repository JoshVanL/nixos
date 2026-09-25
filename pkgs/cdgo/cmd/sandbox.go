package cmd

import (
	"strings"

	"github.com/spf13/cobra"

	"github.com/joshvanl/cdgo/internal/sandbox"
	"github.com/joshvanl/cdgo/internal/workspace"
)

var (
	sandboxResume   bool
	sandboxSettings string
)

var sandboxCmd = &cobra.Command{
	Use:   "sandbox [--resume] <name-or-dir> [group-or-repo...] [-- command...]",
	Short: "Enter (creating if needed) a bubblewrap sandbox for a workspace",
	Long: `Create the workspace if needed, then replace this process with a
bubblewrap sandbox rooted at it: tmpfs home rebuilt from home-manager, no
SSH keys, read-only GH_TOKEN, and only the workspace, ~/.cache, and
~/.claude* writable. Interactive by default; args after -- run
non-interactively through a login shell instead.`,
	Args:              cobra.MinimumNArgs(1),
	ValidArgsFunction: completeWorkspaceNames,
	RunE: func(cmd *cobra.Command, args []string) error {
		var command []string
		if dash := cmd.ArgsLenAtDash(); dash >= 0 {
			command = args[dash:]
			args = args[:dash]
		}

		var dir string
		if strings.Contains(args[0], "/") {
			// Explicit workspace path (internal use by `cdgo job run`);
			// deliberately no meta stamping: jobs are activity, not visits.
			dir = args[0]
		} else {
			var err error
			dir, err = workspace.Create(cfg, args[0], args[1:])
			if err != nil {
				return err
			}
		}

		return sandbox.Exec(cfg, dir, sandbox.Options{
			Resume:           sandboxResume,
			SettingsOverride: sandboxSettings,
			Command:          command,
		})
	},
}

func init() {
	sandboxCmd.Flags().BoolVarP(&sandboxResume, "resume", "r", false, "auto-run `claude-d --continue` on entry")
	sandboxCmd.Flags().StringVar(&sandboxSettings, "settings", "", "ro-bind this file over ~/.claude/settings.json (internal)")
	sandboxCmd.Flags().MarkHidden("settings")
	rootCmd.AddCommand(sandboxCmd)
}
