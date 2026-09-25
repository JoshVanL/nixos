// Package account manages named Claude account credential profiles under
// ~/.claude/accounts/<name>/.
//
// All reads and writes happen inside ~/.claude, which cdgo sandboxes rw
// bind as a directory, so rename-based atomic replacement is safe there.
// This package NEVER writes ~/.claude.json: inside sandboxes it is a bwrap
// file bind (inode pinned, rename-replace breaks it), and the oauthAccount
// block it holds is a cache Claude Code refreshes itself after auth.
//
// A live claude session holds its access token in memory and keeps using
// the old account until its next credential read or token refresh; new
// sessions pick up a switch immediately.
package account

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"time"
)

var nameRe = regexp.MustCompile(`^[a-z0-9][a-z0-9_-]*$`)

func claudeDir() string {
	home, _ := os.UserHomeDir()
	return filepath.Join(home, ".claude")
}

func accountsDir() string { return filepath.Join(claudeDir(), "accounts") }

func credsPath() string { return filepath.Join(claudeDir(), ".credentials.json") }

func currentPath() string { return filepath.Join(accountsDir(), ".current") }

func profileCreds(name string) string {
	return filepath.Join(accountsDir(), name, "credentials.json")
}

func ValidName(name string) error {
	if !nameRe.MatchString(name) {
		return fmt.Errorf("invalid profile name %q (allowed: [a-z0-9_-], must not start with . or -)", name)
	}
	return nil
}

type Profile struct {
	Name         string
	Email        string
	Subscription string
	Current      bool
}

func hashFile(path string) (string, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%x", sha256.Sum256(b)), nil
}

// atomicInstall copies src to dst mode 0600 via temp + rename in dst's dir.
func atomicInstall(src, dst string) error {
	b, err := os.ReadFile(src)
	if err != nil {
		return err
	}
	tmp, err := os.CreateTemp(filepath.Dir(dst), ".tmp-*")
	if err != nil {
		return err
	}
	defer os.Remove(tmp.Name())
	if err := tmp.Chmod(0o600); err != nil {
		tmp.Close()
		return err
	}
	if _, err := tmp.Write(b); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Close(); err != nil {
		return err
	}
	return os.Rename(tmp.Name(), dst)
}

func CurrentName() string {
	b, err := os.ReadFile(currentPath())
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(b))
}

func setCurrent(name string) error {
	if err := os.MkdirAll(accountsDir(), 0o700); err != nil {
		return err
	}
	return os.WriteFile(currentPath(), []byte(name+"\n"), 0o600)
}

// ProfileOfLive returns the profile whose saved credentials byte-match the
// live credentials file.
func ProfileOfLive() (string, bool) {
	liveHash, err := hashFile(credsPath())
	if err != nil {
		return "", false
	}
	names, _ := names()
	for _, n := range names {
		if h, err := hashFile(profileCreds(n)); err == nil && h == liveHash {
			return n, true
		}
	}
	return "", false
}

func names() ([]string, error) {
	entries, err := os.ReadDir(accountsDir())
	if err != nil {
		return nil, err
	}
	var ns []string
	for _, e := range entries {
		if e.IsDir() {
			ns = append(ns, e.Name())
		}
	}
	sort.Strings(ns)
	return ns, nil
}

func List() ([]Profile, error) {
	ns, err := names()
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil
		}
		return nil, err
	}
	cur := CurrentName()
	var ps []Profile
	for _, n := range ns {
		p := Profile{Name: n, Email: "-", Subscription: "-", Current: n == cur}
		if b, err := os.ReadFile(filepath.Join(accountsDir(), n, "oauth-account.json")); err == nil {
			var oa struct {
				EmailAddress string `json:"emailAddress"`
			}
			if json.Unmarshal(b, &oa) == nil && oa.EmailAddress != "" {
				p.Email = oa.EmailAddress
			}
		}
		if b, err := os.ReadFile(profileCreds(n)); err == nil {
			var c struct {
				ClaudeAiOauth struct {
					SubscriptionType string `json:"subscriptionType"`
				} `json:"claudeAiOauth"`
			}
			if json.Unmarshal(b, &c) == nil && c.ClaudeAiOauth.SubscriptionType != "" {
				p.Subscription = c.ClaudeAiOauth.SubscriptionType
			}
		}
		ps = append(ps, p)
	}
	return ps, nil
}

// saveLiveTo copies the live credentials (and an oauthAccount snapshot for
// display) into the named profile.
func saveLiveTo(name string) error {
	dir := filepath.Join(accountsDir(), name)
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return err
	}
	if err := atomicInstall(credsPath(), profileCreds(name)); err != nil {
		return err
	}
	home, _ := os.UserHomeDir()
	if b, err := os.ReadFile(filepath.Join(home, ".claude.json")); err == nil {
		var doc struct {
			OauthAccount json.RawMessage `json:"oauthAccount"`
		}
		if json.Unmarshal(b, &doc) == nil && doc.OauthAccount != nil {
			tmp, err := os.CreateTemp(dir, ".tmp-*")
			if err != nil {
				return err
			}
			defer os.Remove(tmp.Name())
			tmp.Chmod(0o600)
			tmp.Write(doc.OauthAccount)
			tmp.Write([]byte("\n"))
			if err := tmp.Close(); err != nil {
				return err
			}
			if err := os.Rename(tmp.Name(), filepath.Join(dir, "oauth-account.json")); err != nil {
				return err
			}
		}
	}
	return nil
}

// syncLiveToOwner folds the live credentials back into the profile they
// belong to. Tokens rotate on refresh, so the live file drifts from the
// saved copy over time; before any destructive step the freshest tokens
// must be preserved. Fails when ownership of the live file is unknown.
func syncLiveToOwner() error {
	if _, err := os.Stat(credsPath()); err != nil {
		return nil
	}
	cur := CurrentName()
	if cur != "" {
		if _, err := os.Stat(profileCreds(cur)); err == nil {
			return saveLiveTo(cur)
		}
	}
	if owner, ok := ProfileOfLive(); ok {
		if err := setCurrent(owner); err != nil {
			return err
		}
		return saveLiveTo(owner)
	}
	return fmt.Errorf("live credentials do not match any saved profile; run `cdgo account save <name>` to name the current account first")
}

func Save(name string) error {
	if err := ValidName(name); err != nil {
		return err
	}
	if _, err := os.Stat(credsPath()); err != nil {
		return fmt.Errorf("no live credentials at %s", credsPath())
	}
	if err := saveLiveTo(name); err != nil {
		return err
	}
	return setCurrent(name)
}

func Switch(name string) (changed bool, err error) {
	if err := ValidName(name); err != nil {
		return false, err
	}
	if _, err := os.Stat(profileCreds(name)); err != nil {
		return false, fmt.Errorf("no such profile: %s (see `cdgo account list`)", name)
	}
	if err := syncLiveToOwner(); err != nil {
		return false, err
	}
	if CurrentName() == name {
		return false, nil
	}
	if err := atomicInstall(profileCreds(name), credsPath()); err != nil {
		return false, err
	}
	return true, setCurrent(name)
}

// PrepareLogin backs up and removes the live credentials so a fresh
// `claude /login` starts logged out. It returns a restore function that puts
// the original credentials back (used unless the login fully succeeds), and
// the path of a timestamped backup kept as extra insurance.
func PrepareLogin(name string) (restore func() error, backup string, err error) {
	if err := ValidName(name); err != nil {
		return nil, "", err
	}
	if _, err := os.Stat(profileCreds(name)); err == nil {
		return nil, "", fmt.Errorf("profile %q already exists; use `cdgo account switch %s`", name, name)
	}
	if _, err := os.Stat(credsPath()); err != nil {
		// Nothing to protect; login proceeds from a logged-out state.
		return func() error { return nil }, "", nil
	}
	if err := syncLiveToOwner(); err != nil {
		return nil, "", err
	}
	if err := os.MkdirAll(accountsDir(), 0o700); err != nil {
		return nil, "", err
	}
	backup = filepath.Join(accountsDir(), fmt.Sprintf(".pre-login.credentials.json.%d", time.Now().Unix()))
	if err := atomicInstall(credsPath(), backup); err != nil {
		return nil, "", err
	}
	if err := os.Remove(credsPath()); err != nil {
		return nil, backup, err
	}
	restore = func() error { return atomicInstall(backup, credsPath()) }
	return restore, backup, nil
}

// VerifyLive reports whether the live credentials file exists and contains
// an OAuth access token.
func VerifyLive() bool {
	b, err := os.ReadFile(credsPath())
	if err != nil {
		return false
	}
	var c struct {
		ClaudeAiOauth struct {
			AccessToken string `json:"accessToken"`
		} `json:"claudeAiOauth"`
	}
	return json.Unmarshal(b, &c) == nil && c.ClaudeAiOauth.AccessToken != ""
}

// CompleteLogin saves the freshly logged-in credentials as the named profile.
func CompleteLogin(name string) error {
	return Save(name)
}
