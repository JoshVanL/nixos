// Package workspace manages cdgo workspaces under ~/sandbox/workspace:
// creation (concurrent shallow clones), metadata stamping, git status, and
// deletion safety checks.
package workspace

import (
	"crypto/rand"
	"encoding/base32"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"sync"
	"time"

	"github.com/joshvanl/cdgo/internal/config"
)

var nameRe = regexp.MustCompile(`^[a-zA-Z0-9][a-zA-Z0-9._-]*$`)

func Root() string {
	home, _ := os.UserHomeDir()
	return filepath.Join(home, "sandbox", "workspace")
}

func Dir(name string) string {
	return filepath.Join(Root(), name)
}

func ValidName(name string) error {
	if !nameRe.MatchString(name) {
		return fmt.Errorf("invalid workspace name %q", name)
	}
	return nil
}

func RandomName() string {
	b := make([]byte, 6)
	if _, err := rand.Read(b); err != nil {
		panic(err)
	}
	enc := base32.HexEncoding.WithPadding(base32.NoPadding)
	return strings.ToLower(enc.EncodeToString(b))
}

// Meta is stamped into <workspace>/.cdgo/meta.json.
type Meta struct {
	CreatedAt     time.Time `json:"created_at"`
	CreatedApprox bool      `json:"created_approx,omitempty"`
	LastEnteredAt time.Time `json:"last_entered_at"`
	EnteredCount  int       `json:"entered_count"`
	Args          []string  `json:"args,omitempty"`
}

func metaPath(dir string) string { return filepath.Join(dir, ".cdgo", "meta.json") }

func LoadMeta(dir string) (*Meta, error) {
	b, err := os.ReadFile(metaPath(dir))
	if err != nil {
		return nil, err
	}
	var m Meta
	if err := json.Unmarshal(b, &m); err != nil {
		return nil, err
	}
	return &m, nil
}

// StampEntered records a visit, creating or backfilling meta.json as needed.
// isNew marks a workspace created by this invocation, whose creation time is
// exact; otherwise a missing meta.json is backfilled approximately from the
// directory mtime.
func StampEntered(dir string, args []string, isNew bool) error {
	m, err := LoadMeta(dir)
	if err != nil {
		m = &Meta{CreatedAt: time.Now()}
		if !isNew {
			if fi, serr := os.Stat(dir); serr == nil {
				m.CreatedAt = fi.ModTime()
				m.CreatedApprox = true
			}
		}
	}
	m.LastEnteredAt = time.Now()
	m.EnteredCount++
	if len(args) > 0 {
		m.Args = args
	}
	return WriteJSONAtomic(metaPath(dir), m)
}

// WriteJSONAtomic writes v as JSON via a temp file + rename in the target
// directory, creating the directory first.
func WriteJSONAtomic(path string, v any) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	b, err := json.MarshalIndent(v, "", "  ")
	if err != nil {
		return err
	}
	tmp, err := os.CreateTemp(filepath.Dir(path), ".tmp-*")
	if err != nil {
		return err
	}
	defer os.Remove(tmp.Name())
	if _, err := tmp.Write(append(b, '\n')); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Close(); err != nil {
		return err
	}
	return os.Rename(tmp.Name(), path)
}

// ExpandGroups resolves each arg to repos via the config groups, leaving
// unknown args as literal "owner/repo" entries.
func ExpandGroups(cfg *config.Config, args []string) []string {
	var repos []string
	for _, a := range args {
		if rs, ok := cfg.Groups[a]; ok {
			fmt.Fprintf(os.Stderr, ">> expanding group %q\n", a)
			repos = append(repos, rs...)
		} else {
			repos = append(repos, a)
		}
	}
	return repos
}

// Create makes the workspace directory, clones repos concurrently, seeds
// .claude/settings.json and CLAUDE.md, and stamps meta.json. It is
// idempotent: existing clones and files are left alone.
func Create(cfg *config.Config, name string, repoArgs []string) (string, error) {
	if err := ValidName(name); err != nil {
		return "", err
	}
	dir := Dir(name)
	_, statErr := os.Stat(dir)
	isNew := os.IsNotExist(statErr)
	fmt.Fprintf(os.Stderr, ">> mkdir -p %s\n", dir)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return "", err
	}

	repos := ExpandGroups(cfg, repoArgs)

	var wg sync.WaitGroup
	errCh := make(chan error, len(repos))
	for _, repo := range repos {
		owner, repoName, ok := strings.Cut(repo, "/")
		if !ok {
			return "", fmt.Errorf("invalid repo %q: want owner/repo or a group name", repo)
		}
		repoDir := filepath.Join(dir, repoName)
		if _, err := os.Stat(repoDir); err == nil {
			fmt.Fprintf(os.Stderr, ">> skipping %s: %s already exists\n", repo, repoDir)
			continue
		}
		wg.Add(1)
		go func() {
			defer wg.Done()
			url := "https://github.com/" + repo
			fmt.Fprintf(os.Stderr, ">> git clone --no-single-branch --depth 1 %s %s\n", url, repoDir)
			cmd := exec.Command("git", "clone", "--no-single-branch", "--depth", "1", url, repoDir)
			cmd.Stdout = os.Stderr
			cmd.Stderr = os.Stderr
			if err := cmd.Run(); err != nil {
				errCh <- fmt.Errorf("clone %s: %w", repo, err)
				return
			}
			if owner != "joshvanl" {
				fork := "git@github.com:joshvanl/" + repoName + ".git"
				fmt.Fprintf(os.Stderr, ">> git -C %s remote add fork %s\n", repoDir, fork)
				cmd := exec.Command("git", "-C", repoDir, "remote", "add", "fork", fork)
				cmd.Stdout = os.Stderr
				cmd.Stderr = os.Stderr
				if err := cmd.Run(); err != nil {
					errCh <- fmt.Errorf("add fork remote to %s: %w", repo, err)
				}
			}
		}()
	}
	wg.Wait()
	close(errCh)
	for err := range errCh {
		return "", err
	}

	if err := seedFile(cfg.WorkspaceSettingsFile, filepath.Join(dir, ".claude", "settings.json")); err != nil {
		return "", err
	}
	if err := seedFile(cfg.ClaudeMdFile, filepath.Join(dir, "CLAUDE.md")); err != nil {
		return "", err
	}
	if err := StampEntered(dir, repoArgs, isNew); err != nil {
		return "", err
	}
	return dir, nil
}

func seedFile(src, dst string) error {
	if src == "" {
		return nil
	}
	if _, err := os.Stat(dst); err == nil {
		fmt.Fprintf(os.Stderr, ">> skipping %s: already exists\n", dst)
		return nil
	}
	if err := os.MkdirAll(filepath.Dir(dst), 0o755); err != nil {
		return err
	}
	fmt.Fprintf(os.Stderr, ">> writing %s\n", dst)
	b, err := os.ReadFile(src)
	if err != nil {
		return err
	}
	return os.WriteFile(dst, b, 0o644)
}
