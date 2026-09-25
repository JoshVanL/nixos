// Package sandbox builds and execs the bubblewrap sandbox around a cdgo
// workspace: tmpfs home reconstructed from the home-manager store tree, no
// SSH keys or host sockets, a read-only GH_TOKEN, and only the workspace,
// ~/.cache, and ~/.claude* writable.
package sandbox

import (
	"fmt"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"

	"github.com/joshvanl/cdgo/internal/config"
)

type Options struct {
	// Resume sets CDGO_RESUME=1 so the sandbox shell auto-runs
	// `claude-d --continue` on entry.
	Resume bool

	// SettingsOverride is ro-bound over ~/.claude/settings.json (used by
	// jobs to relax the git commit deny).
	SettingsOverride string

	// Command, when non-empty, runs non-interactively through a login shell
	// instead of starting an interactive shell.
	Command []string
}

// Exec replaces the current process with bwrap. It only returns on error.
func Exec(cfg *config.Config, dir string, opts Options) error {
	if fi, err := os.Stat(dir); err != nil || !fi.IsDir() {
		return fmt.Errorf("workspace directory does not exist: %s", dir)
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return err
	}
	uid := os.Getuid()

	args := []string{
		"--unshare-all",
		"--share-net",

		// System essentials
		"--proc", "/proc",
		"--dev", "/dev",
		"--tmpfs", "/tmp",

		// Nix store (all tools live here)
		"--ro-bind", "/nix/store", "/nix/store",
		"--ro-bind", "/nix/var", "/nix/var",

		// System binaries and zsh
		"--ro-bind", "/run/current-system", "/run/current-system",

		// FHS shims: /bin/sh and /usr/bin/env (symlinks into /nix/store)
		"--ro-bind", "/bin", "/bin",
		"--ro-bind", "/usr/bin", "/usr/bin",

		// Networking and identity
		"--ro-bind", "/etc/resolv.conf", "/etc/resolv.conf",
		"--ro-bind", "/etc/hosts", "/etc/hosts",
		"--ro-bind", "/etc/ssl", "/etc/ssl",
		"--ro-bind", "/etc/static", "/etc/static",
		"--ro-bind", "/etc/passwd", "/etc/passwd",
		"--ro-bind", "/etc/group", "/etc/group",
		"--ro-bind", "/etc/nsswitch.conf", "/etc/nsswitch.conf",
		"--ro-bind", "/etc/profiles", "/etc/profiles",

		// Timezone: /etc/localtime is a symlink chain into /nix/store
		// (already bound), so a single bind lets glibc resolve the local
		// timezone instead of falling back to UTC.
		"--ro-bind", "/etc/localtime", "/etc/localtime",

		// Empty home, then selective mounts on top
		"--tmpfs", home,
	}

	// Bind home-manager dotfiles (read-only) so zsh, oh-my-zsh, neovim, etc.
	// work. Home-manager creates symlinks from $HOME into /nix/store; the
	// home-manager-files store path is resolved from .zshrc and the whole
	// tree bound, which recreates all managed dotfile symlinks.
	// .ssh is skipped entirely (no SSH identity in the sandbox), .config and
	// .local are handled separately.
	hmFiles := ""
	if target, err := os.Readlink(filepath.Join(home, ".zshrc")); err == nil {
		hmFiles = strings.TrimSuffix(target, "/.zshrc")
	}
	if hmFiles != "" {
		if entries, err := os.ReadDir(hmFiles); err == nil {
			for _, e := range entries {
				switch e.Name() {
				case ".ssh", ".config", ".local":
					continue
				}
				args = append(args, "--ro-bind", filepath.Join(hmFiles, e.Name()), filepath.Join(home, e.Name()))
			}
		}
		if _, err := os.Stat(filepath.Join(hmFiles, ".config")); err == nil {
			args = append(args, "--ro-bind", filepath.Join(hmFiles, ".config"), filepath.Join(home, ".config"))
		}
	}

	// .local: writable base with home-manager entries (fonts, desktop files)
	// bound ro on top. Neovim needs to write .local/share|state/nvim.
	args = append(args, "--tmpfs", filepath.Join(home, ".local"))
	if hmFiles != "" {
		localRoot := filepath.Join(hmFiles, ".local")
		_ = filepath.WalkDir(localRoot, func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return nil
			}
			rel, rerr := filepath.Rel(hmFiles, path)
			if rerr != nil {
				return nil
			}
			if d.IsDir() {
				// Match `find -maxdepth 3`: entries at most 3 levels below
				// hm_files are considered.
				if strings.Count(rel, string(filepath.Separator)) >= 3 {
					return fs.SkipDir
				}
				return nil
			}
			args = append(args, "--ro-bind", path, filepath.Join(home, rel))
			return nil
		})
	}

	// Cache directory (rw) for oh-my-zsh completions, go-build, etc.
	cache := filepath.Join(home, ".cache")
	if _, err := os.Stat(cache); err == nil {
		args = append(args, "--bind", cache, cache)
	} else {
		args = append(args, "--dir", cache)
	}

	// The workspace (read-write)
	args = append(args, "--bind", dir, dir)

	// /run/user/$UID: writable tmpfs so neovim can create sockets.
	// No SSH agent or other host sockets exposed.
	args = append(args, "--tmpfs", fmt.Sprintf("/run/user/%d", uid))

	// Claude Code config (read-write for session state)
	claudeDir := filepath.Join(home, ".claude")
	if _, err := os.Stat(claudeDir); err == nil {
		args = append(args, "--bind", claudeDir, claudeDir)
		// Settings override must come after the ~/.claude directory bind so
		// the file bind shadows the settings inside it.
		if opts.SettingsOverride != "" {
			if _, err := os.Stat(opts.SettingsOverride); err == nil {
				args = append(args, "--ro-bind", opts.SettingsOverride, filepath.Join(claudeDir, "settings.json"))
			}
		}
	}
	claudeJSON := filepath.Join(home, ".claude.json")
	if _, err := os.Stat(claudeJSON); err == nil {
		args = append(args, "--bind", claudeJSON, claudeJSON)
	}

	// Go module + build cache (read-only)
	goPkg := filepath.Join(home, "go", "pkg")
	if _, err := os.Stat(goPkg); err == nil {
		args = append(args, "--dir", filepath.Join(home, "go"), "--ro-bind", goPkg, goPkg)
	}

	// Extra read-only binds from nix config
	for _, p := range cfg.SandboxExtraRoBinds {
		if p == "" {
			continue
		}
		if _, err := os.Stat(p); err == nil {
			args = append(args, "--ro-bind", p, p)
		}
	}

	user := os.Getenv("USER")
	token, err := os.ReadFile(cfg.GithubReadOnlyTokenFile)
	if err != nil {
		return fmt.Errorf("read github token: %w", err)
	}

	args = append(args,
		"--chdir", dir,
		"--setenv", "HOME", home,
		"--setenv", "USER", user,
		"--setenv", "CDGO_SANDBOX", "1",
		"--setenv", "CDGO_WORKSPACE", dir,
		"--setenv", "GH_TOKEN", strings.TrimSpace(string(token)),
	)
	if opts.Resume {
		args = append(args, "--setenv", "CDGO_RESUME", "1")
	}

	const zsh = "/run/current-system/sw/bin/zsh"
	if len(opts.Command) > 0 {
		// A login shell sets up the system PATH for the command.
		cmd := "exec " + shellQuote(opts.Command)
		fmt.Fprintf(os.Stderr, ">> Running in sandbox for: %s: %s\n", dir, shellQuote(opts.Command))
		args = append(args, "--", zsh, "-lc", cmd)
	} else {
		fmt.Fprintf(os.Stderr, ">> Entering sandbox for: %s\n", dir)
		args = append(args, "--", zsh, "-l")
	}

	bwrap, err := exec.LookPath("bwrap")
	if err != nil {
		return fmt.Errorf("bwrap not found: %w", err)
	}
	return syscall.Exec(bwrap, append([]string{"bwrap"}, args...), os.Environ())
}

func shellQuote(argv []string) string {
	quoted := make([]string, len(argv))
	for i, a := range argv {
		quoted[i] = "'" + strings.ReplaceAll(a, "'", `'\''`) + "'"
	}
	return strings.Join(quoted, " ")
}
