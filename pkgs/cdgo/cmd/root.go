// Package cmd implements the cdgo CLI: disposable multi-repo workspaces,
// bubblewrap sandboxes for claude, background job agents, and Claude
// account profile switching.
package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"

	"github.com/joshvanl/cdgo/internal/config"
	"github.com/joshvanl/cdgo/internal/workspace"
)

var cfg *config.Config

var rootCmd = &cobra.Command{
	Use:           "cdgo",
	Short:         "Disposable multi-repo claude workspaces, sandboxes, and background jobs",
	SilenceUsage:  true,
	SilenceErrors: true,
	// The zsh wrapper treats a non-subcommand first arg as `create <name>`,
	// so bare completion offers workspace names alongside subcommands.
	ValidArgsFunction: completeWorkspaceNames,
	PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
		var err error
		cfg, err = config.Load()
		return err
	},
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, ">> error: %v\n", err)
		os.Exit(1)
	}
}

// completeWorkspaceNames offers existing workspace names for the first
// positional arg and group names afterwards.
func completeWorkspaceNames(cmd *cobra.Command, args []string, toComplete string) ([]string, cobra.ShellCompDirective) {
	if len(args) == 0 {
		entries, err := os.ReadDir(workspace.Root())
		if err != nil {
			return nil, cobra.ShellCompDirectiveNoFileComp
		}
		var names []string
		for _, e := range entries {
			if e.IsDir() {
				names = append(names, e.Name())
			}
		}
		return names, cobra.ShellCompDirectiveNoFileComp
	}
	return completeGroupNames(cmd, args, toComplete)
}

func completeGroupNames(cmd *cobra.Command, args []string, toComplete string) ([]string, cobra.ShellCompDirective) {
	c, err := config.Load()
	if err != nil {
		return nil, cobra.ShellCompDirectiveNoFileComp
	}
	var names []string
	for g := range c.Groups {
		names = append(names, g)
	}
	return names, cobra.ShellCompDirectiveNoFileComp
}

// completeJobNames offers workspaces that have job state.
func completeJobNames(cmd *cobra.Command, args []string, toComplete string) ([]string, cobra.ShellCompDirective) {
	if len(args) > 0 {
		return nil, cobra.ShellCompDirectiveNoFileComp
	}
	entries, err := os.ReadDir(workspace.Root())
	if err != nil {
		return nil, cobra.ShellCompDirectiveNoFileComp
	}
	var names []string
	for _, e := range entries {
		if !e.IsDir() {
			continue
		}
		if _, err := os.Stat(workspace.Dir(e.Name()) + "/.cdgo/job.json"); err == nil {
			names = append(names, e.Name())
		}
	}
	return names, cobra.ShellCompDirectiveNoFileComp
}
