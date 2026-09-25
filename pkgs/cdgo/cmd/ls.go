package cmd

import (
	"fmt"
	"os"
	"strings"
	"text/tabwriter"

	"github.com/spf13/cobra"

	"github.com/joshvanl/cdgo/internal/job"
	"github.com/joshvanl/cdgo/internal/workspace"
)

var lsCmd = &cobra.Command{
	Use:   "ls",
	Short: "List workspaces with age, last entered, activity, size, and status",
	RunE: func(cmd *cobra.Command, args []string) error {
		infos, err := workspace.List(true)
		if err != nil {
			return err
		}
		if len(infos) == 0 {
			fmt.Fprintln(os.Stderr, ">> no workspaces")
			return nil
		}
		w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
		fmt.Fprintln(w, "NAME\tAGE\tENTERED\tACTIVITY\tSIZE\tREPOS\tSTATUS")
		for _, i := range infos {
			age, entered := "-", "-"
			if i.Meta != nil {
				age = workspace.Humanize(i.Meta.CreatedAt)
				if i.Meta.CreatedApprox {
					age = "~" + age
				}
				entered = fmt.Sprintf("%s (%dx)", workspace.Ago(i.Meta.LastEnteredAt), i.Meta.EnteredCount)
			}
			var repos []string
			for _, r := range i.Repos {
				repos = append(repos, r.Name)
			}
			repoCol := strings.Join(repos, ",")
			if len(repoCol) > 40 {
				repoCol = fmt.Sprintf("%d repos", len(repos))
			}
			status := "clean"
			if i.Dirty() {
				status = "dirty: " + i.DirtyDetail()
			}
			if j, err := job.Load(i.Dir); err == nil {
				status += " job:" + j.Status
			}
			size := i.Size
			if size == "" {
				size = "-"
			}
			fmt.Fprintf(w, "%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
				i.Name, age, entered, workspace.Ago(i.LastActivity),
				size, repoCol, status)
		}
		return w.Flush()
	},
}

func init() {
	rootCmd.AddCommand(lsCmd)
}
