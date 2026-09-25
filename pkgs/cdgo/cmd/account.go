package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"text/tabwriter"

	"github.com/spf13/cobra"

	"github.com/joshvanl/cdgo/internal/account"
)

var accountCmd = &cobra.Command{
	Use:   "account",
	Short: "Manage named Claude account credential profiles",
}

func completeAccountNames(cmd *cobra.Command, args []string, toComplete string) ([]string, cobra.ShellCompDirective) {
	if len(args) > 0 {
		return nil, cobra.ShellCompDirectiveNoFileComp
	}
	ps, err := account.List()
	if err != nil {
		return nil, cobra.ShellCompDirectiveNoFileComp
	}
	var names []string
	for _, p := range ps {
		names = append(names, p.Name)
	}
	return names, cobra.ShellCompDirectiveNoFileComp
}

var accountListCmd = &cobra.Command{
	Use:     "list",
	Aliases: []string{"ls"},
	Short:   "List saved account profiles",
	RunE: func(cmd *cobra.Command, args []string) error {
		ps, err := account.List()
		if err != nil {
			return err
		}
		if len(ps) == 0 {
			fmt.Fprintln(os.Stderr, ">> no profiles saved. run: cdgo account save <name>")
			return nil
		}
		w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
		for _, p := range ps {
			marker := " "
			if p.Current {
				marker = "*"
			}
			fmt.Fprintf(w, "%s %s\t%s\t%s\n", marker, p.Name, p.Email, p.Subscription)
		}
		return w.Flush()
	},
}

var accountCurrentCmd = &cobra.Command{
	Use:   "current",
	Short: "Show the active profile name",
	RunE: func(cmd *cobra.Command, args []string) error {
		if cur := account.CurrentName(); cur != "" {
			fmt.Println(cur)
			return nil
		}
		if owner, ok := account.ProfileOfLive(); ok {
			fmt.Println(owner)
			return nil
		}
		fmt.Println("unknown (run: cdgo account save <name>)")
		return nil
	},
}

var accountSaveCmd = &cobra.Command{
	Use:   "save <name>",
	Short: "Save the live credentials as a profile",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		if err := account.Save(args[0]); err != nil {
			return err
		}
		fmt.Fprintf(os.Stderr, ">> saved live credentials as profile: %s\n", args[0])
		return nil
	},
}

var accountSwitchCmd = &cobra.Command{
	Use:               "switch <name>",
	Short:             "Swap the live credentials to a saved profile",
	Args:              cobra.ExactArgs(1),
	ValidArgsFunction: completeAccountNames,
	RunE: func(cmd *cobra.Command, args []string) error {
		changed, err := account.Switch(args[0])
		if err != nil {
			return err
		}
		if !changed {
			fmt.Fprintf(os.Stderr, ">> already on profile: %s\n", args[0])
			return nil
		}
		fmt.Fprintf(os.Stderr, ">> switched to profile: %s\n", args[0])
		fmt.Fprintln(os.Stderr, ">> running claude sessions keep their in-memory token until the next")
		fmt.Fprintln(os.Stderr, ">> refresh; new sessions use the new account immediately.")
		return nil
	},
}

var accountLoginCmd = &cobra.Command{
	Use:   "login <name>",
	Short: "Log in to a new account and save it as a profile",
	Long: `Bootstrap an additional account without risking the current one: the live
credentials must already be saved as a profile, a timestamped backup is
kept, and on any failure the original credentials are restored. Runs
claude's interactive /login flow; complete it, then exit claude.`,
	Args: cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		name := args[0]
		restore, backup, err := account.PrepareLogin(name)
		if err != nil {
			return err
		}
		completed := false
		defer func() {
			if !completed {
				if rerr := restore(); rerr != nil {
					fmt.Fprintf(os.Stderr, ">> error: restoring credentials: %v (backup: %s)\n", rerr, backup)
				} else {
					fmt.Fprintln(os.Stderr, ">> login did not complete: restored previous credentials.")
				}
			}
		}()

		fmt.Fprintln(os.Stderr, ">> starting claude to log in to the new account.")
		fmt.Fprintln(os.Stderr, ">> complete the /login flow, then exit claude to continue.")
		login := exec.Command("claude", "/login")
		login.Stdin = os.Stdin
		login.Stdout = os.Stdout
		login.Stderr = os.Stderr
		_ = login.Run()

		if !account.VerifyLive() {
			return fmt.Errorf("no valid credentials found after login")
		}
		if err := account.CompleteLogin(name); err != nil {
			return err
		}
		completed = true
		fmt.Fprintf(os.Stderr, ">> logged in and saved profile: %s\n", name)
		if backup != "" {
			fmt.Fprintf(os.Stderr, ">> previous account kept at: %s (and its named profile)\n", backup)
		}
		return nil
	},
}

func init() {
	accountCmd.AddCommand(accountListCmd, accountCurrentCmd, accountSaveCmd, accountSwitchCmd, accountLoginCmd)
	rootCmd.AddCommand(accountCmd)
}
