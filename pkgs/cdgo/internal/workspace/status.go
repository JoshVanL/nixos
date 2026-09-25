package workspace

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"
)

// RepoStatus describes why a repo is dirty.
type RepoStatus struct {
	Name        string
	Uncommitted bool
	Unpushed    bool
	Stashes     bool
}

func (r RepoStatus) Dirty() bool { return r.Uncommitted || r.Unpushed || r.Stashes }

func (r RepoStatus) Reasons() string {
	var rs []string
	if r.Uncommitted {
		rs = append(rs, "uncommitted")
	}
	if r.Unpushed {
		rs = append(rs, "unpushed")
	}
	if r.Stashes {
		rs = append(rs, "stashes")
	}
	return strings.Join(rs, "+")
}

// Info is the full status of one workspace.
type Info struct {
	Name         string
	Dir          string
	Meta         *Meta
	LastActivity time.Time
	Repos        []RepoStatus
	Size         string
}

func (i Info) Dirty() bool {
	for _, r := range i.Repos {
		if r.Dirty() {
			return true
		}
	}
	return false
}

func (i Info) DirtyDetail() string {
	var ds []string
	for _, r := range i.Repos {
		if r.Dirty() {
			ds = append(ds, r.Name+":"+r.Reasons())
		}
	}
	return strings.Join(ds, " ")
}

// LastUsed is the most recent signal that the workspace matters: entering it
// or file activity inside it (e.g. a background job writing).
func (i Info) LastUsed() time.Time {
	t := i.LastActivity
	if i.Meta != nil && i.Meta.LastEnteredAt.After(t) {
		t = i.Meta.LastEnteredAt
	}
	return t
}

func gitQuiet(dir string, args ...string) string {
	cmd := exec.Command("git", append([]string{"-C", dir}, args...)...)
	out, err := cmd.Output()
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(out))
}

func repoStatus(dir string) RepoStatus {
	return RepoStatus{
		Name:        filepath.Base(dir),
		Uncommitted: gitQuiet(dir, "status", "--porcelain") != "",
		Unpushed:    gitQuiet(dir, "log", "--branches", "--not", "--remotes", "--oneline", "-1") != "",
		Stashes:     gitQuiet(dir, "stash", "list") != "",
	}
}

// Inspect gathers the status of a single workspace directory.
func Inspect(dir string, withSize bool) (*Info, error) {
	fi, err := os.Stat(dir)
	if err != nil {
		return nil, err
	}
	info := &Info{
		Name:         filepath.Base(dir),
		Dir:          dir,
		LastActivity: fi.ModTime(),
	}
	if m, err := LoadMeta(dir); err == nil {
		info.Meta = m
	}

	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil, err
	}
	for _, e := range entries {
		if !e.IsDir() {
			continue
		}
		repoDir := filepath.Join(dir, e.Name())
		if _, err := os.Stat(filepath.Join(repoDir, ".git")); err != nil {
			continue
		}
		// Cheap activity signal without a full tree walk. Collected BEFORE
		// repoStatus: `git status` refreshes the index and would reset its
		// mtime to now.
		for _, f := range []string{".git/index", ".git/HEAD"} {
			if st, err := os.Stat(filepath.Join(repoDir, f)); err == nil && st.ModTime().After(info.LastActivity) {
				info.LastActivity = st.ModTime()
			}
		}
		info.Repos = append(info.Repos, repoStatus(repoDir))
	}
	// Job state changes also count as activity.
	if st, err := os.Stat(filepath.Join(dir, ".cdgo", "job.json")); err == nil && st.ModTime().After(info.LastActivity) {
		info.LastActivity = st.ModTime()
	}

	if withSize {
		out, err := exec.Command("du", "-sh", dir).Output()
		if err == nil {
			info.Size, _, _ = strings.Cut(strings.TrimSpace(string(out)), "\t")
		}
	}
	return info, nil
}

// List inspects every workspace concurrently (git status and du dominate on
// cold caches), most recently used first.
func List(withSize bool) ([]*Info, error) {
	entries, err := os.ReadDir(Root())
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil
		}
		return nil, err
	}
	var (
		mu    sync.Mutex
		wg    sync.WaitGroup
		infos []*Info
	)
	for _, e := range entries {
		if !e.IsDir() || strings.HasPrefix(e.Name(), ".") {
			continue
		}
		wg.Add(1)
		go func() {
			defer wg.Done()
			info, err := Inspect(filepath.Join(Root(), e.Name()), withSize)
			if err != nil {
				fmt.Fprintf(os.Stderr, ">> warning: %s: %v\n", e.Name(), err)
				return
			}
			mu.Lock()
			infos = append(infos, info)
			mu.Unlock()
		}()
	}
	wg.Wait()
	sort.Slice(infos, func(a, b int) bool {
		return infos[a].LastUsed().After(infos[b].LastUsed())
	})
	return infos, nil
}

// Humanize renders a time as a compact age like "3d" or "2h".
func Humanize(t time.Time) string {
	if t.IsZero() {
		return "-"
	}
	d := time.Since(t)
	switch {
	case d < time.Minute:
		return "now"
	case d < time.Hour:
		return fmt.Sprintf("%dm", int(d.Minutes()))
	case d < 24*time.Hour:
		return fmt.Sprintf("%dh", int(d.Hours()))
	case d < 14*24*time.Hour:
		return fmt.Sprintf("%dd", int(d.Hours()/24))
	default:
		return fmt.Sprintf("%dw", int(d.Hours()/(24*7)))
	}
}

// Ago renders a time as "2h ago", or "now" / "-" when appropriate.
func Ago(t time.Time) string {
	h := Humanize(t)
	if h == "now" || h == "-" {
		return h
	}
	return h + " ago"
}
