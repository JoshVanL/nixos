// cdpr checks out a GitHub pull request in a cdgo workspace, to review it
// locally.
package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"syscall"

	"github.com/spf13/cobra"
)

func main() {
	var (
		sandbox bool
		cwdFile string
	)
	root := &cobra.Command{
		Use:   "cdpr <pr>",
		Short: "Check out a GitHub pull request in a cdgo workspace, to review it locally",
		Long: `cdpr clones the repo of a pull request into the cdgo workspace
~/sandbox/workspace/<repo>-pr-<number>, checks out the pull request, and prints
a summary with the command that diffs it against its base branch.

The clone keeps the full history, so that diff works. Running cdpr again on the
same pull request reuses the clone and pulls in new commits.`,
		Example: `  cdpr https://github.com/dapr/kit/pull/173
  cdpr dapr/kit#173
  cdpr --sandbox dapr/kit#173`,
		Args:         cobra.ExactArgs(1),
		SilenceUsage: true,
		RunE: func(_ *cobra.Command, args []string) error {
			owner, repo, n, err := parsePR(args[0])
			if err != nil {
				return err
			}

			var sandboxPath string
			if sandbox {
				if sandboxPath, err = exec.LookPath("__cdgo_sandbox"); err != nil {
					return errors.New("cdgo sandbox is not enabled on this machine")
				}
			}

			dir, ws, err := checkout(owner, repo, n)
			if err != nil {
				return err
			}

			if sandbox {
				return syscall.Exec(sandboxPath, []string{"__cdgo_sandbox", ws}, os.Environ())
			}
			if cwdFile != "" {
				return os.WriteFile(cwdFile, []byte(dir), 0o600)
			}
			return nil
		},
	}
	// Nothing completes but flags, and zsh completion would call the cdpr
	// shell function rather than this binary.
	root.CompletionOptions.DisableDefaultCmd = true
	root.Flags().BoolVarP(&sandbox, "sandbox", "s", false, "enter cdgo-sandbox for the workspace after checkout")
	root.Flags().StringVar(&cwdFile, "cwd-file", "", "write the repo directory to this file, for the cdpr shell function to cd into")
	_ = root.Flags().MarkHidden("cwd-file")

	if err := root.Execute(); err != nil {
		os.Exit(1)
	}
}

var (
	urlRE   = regexp.MustCompile(`^https://github\.com/([\w.-]+)/([\w.-]+)/pull/(\d+)(?:[/?#].*)?$`)
	shortRE = regexp.MustCompile(`^([\w.-]+)/([\w.-]+)#(\d+)$`)
)

// parsePR reads a pull request URL, or owner/repo#number.
func parsePR(arg string) (owner, repo string, n int, err error) {
	m := urlRE.FindStringSubmatch(arg)
	if m == nil {
		m = shortRE.FindStringSubmatch(arg)
	}
	if m == nil {
		return "", "", 0, fmt.Errorf("%q is not a pull request URL or owner/repo#number", arg)
	}
	for _, name := range m[1:3] {
		if name == "." || name == ".." {
			return "", "", 0, fmt.Errorf("%q is not an owner or repo name", name)
		}
	}
	if n, err = strconv.Atoi(m[3]); err != nil {
		return "", "", 0, fmt.Errorf("%q is not a pull request number", m[3])
	}
	return m[1], m[2], n, nil
}

// checkout clones the repo into its cdgo workspace if needed, checks out the
// pull request, and prints its summary. It returns the repo and workspace
// directories.
func checkout(owner, repo string, n int) (dir, ws string, err error) {
	nwo, num := owner+"/"+repo, strconv.Itoa(n)

	// cdgo sets up the workspace, with its CLAUDE.md and Claude settings, and
	// prints its directory.
	out, err := output("", "__cdgo", repo+"-pr-"+num)
	if err != nil {
		return "", "", err
	}
	ws = strings.TrimSpace(string(out))
	dir = filepath.Join(ws, repo)

	if _, err := os.Stat(dir); errors.Is(err, fs.ErrNotExist) {
		// Blobless rather than shallow, so the pull request can be diffed
		// against its base.
		if err := run("", "git", "clone", "--filter=blob:none", "https://github.com/"+nwo, dir); err != nil {
			return "", "", err
		}
	} else if err != nil {
		return "", "", err
	}

	if err := run(dir, "gh", "pr", "checkout", num, "-R", nwo); err != nil {
		return "", "", err
	}

	out, err = output(dir, "gh", "pr", "view", num, "-R", nwo, "--json",
		"title,author,baseRefName,headRefName,changedFiles,additions,deletions")
	if err != nil {
		return "", "", err
	}
	var pr struct {
		Title  string
		Author struct {
			Login string
		}
		BaseRefName, HeadRefName           string
		ChangedFiles, Additions, Deletions int
	}
	if err := json.Unmarshal(out, &pr); err != nil {
		return "", "", fmt.Errorf("gh pr view: %w", err)
	}

	// Keeps origin/<base> current for the diff when cdpr runs again later.
	if err := run(dir, "git", "fetch", "origin", pr.BaseRefName); err != nil {
		return "", "", err
	}

	files := "files"
	if pr.ChangedFiles == 1 {
		files = "file"
	}
	fmt.Printf("%s#%d  %s\n", nwo, n, pr.Title)
	fmt.Printf("by %s  %s -> %s  %d %s, +%d -%d\n",
		pr.Author.Login, pr.HeadRefName, pr.BaseRefName, pr.ChangedFiles, files, pr.Additions, pr.Deletions)
	fmt.Printf("review: git diff origin/%s...HEAD\n", pr.BaseRefName)
	return dir, ws, nil
}

// run runs a command in dir with its output on stderr, keeping stdout for the
// summary.
func run(dir, name string, args ...string) error {
	fmt.Fprintf(os.Stderr, ">> %s %s\n", name, strings.Join(args, " "))
	cmd := exec.Command(name, args...)
	cmd.Dir = dir
	cmd.Stdout, cmd.Stderr = os.Stderr, os.Stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("%s: %w", name, err)
	}
	return nil
}

// output runs a command in dir and returns its stdout.
func output(dir, name string, args ...string) ([]byte, error) {
	cmd := exec.Command(name, args...)
	cmd.Dir = dir
	cmd.Stderr = os.Stderr
	out, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("%s: %w", name, err)
	}
	return out, nil
}
