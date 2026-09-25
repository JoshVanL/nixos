package cmd

import (
	"fmt"

	"github.com/spf13/cobra"

	"github.com/joshvanl/cdgo/internal/workspace"
)

var createCmd = &cobra.Command{
	Use:   "create [name] [group-or-repo...]",
	Short: "Create (or revisit) a workspace, cloning repos concurrently",
	Long: `Create a workspace under ~/sandbox/workspace/<name>, shallow-cloning the
given repos or groups concurrently, and seed .claude/settings.json and
CLAUDE.md. Idempotent: an existing workspace is revisited. With no name, a
random one is generated. The workspace path is printed on stdout so shell
wrappers can cd into it; all logging goes to stderr.`,
	ValidArgsFunction: completeWorkspaceNames,
	RunE: func(cmd *cobra.Command, args []string) error {
		name := ""
		var repos []string
		if len(args) > 0 {
			name = args[0]
			repos = args[1:]
		}
		if name == "" {
			name = workspace.RandomName()
		}
		dir, err := workspace.Create(cfg, name, repos)
		if err != nil {
			return err
		}
		fmt.Println(dir)
		return nil
	},
}

func init() {
	rootCmd.AddCommand(createCmd)
}
