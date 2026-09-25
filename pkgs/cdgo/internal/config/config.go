// Package config loads the nix-generated cdgo configuration. The nix module
// wraps the cdgo binary with CDGO_CONFIG pointing at a JSON file in the
// store; running unwrapped (e.g. go run) works with an empty config.
package config

import (
	"encoding/json"
	"fmt"
	"os"
)

type JobTemplate struct {
	Prompt string   `json:"prompt"`
	Groups []string `json:"groups"`
}

type Config struct {
	// Groups maps a group name to a list of "owner/repo" entries.
	Groups map[string][]string `json:"groups"`

	// JobTemplates maps a template name to a canned goal prompt and groups.
	JobTemplates map[string]JobTemplate `json:"jobTemplates"`

	// ClaudeMdFile is copied into new workspaces as CLAUDE.md.
	ClaudeMdFile string `json:"claudeMdFile"`

	// WorkspaceSettingsFile seeds <workspace>/.claude/settings.json.
	WorkspaceSettingsFile string `json:"workspaceSettingsFile"`

	// JobEpilogueFile is appended to every job goal (finish protocol).
	JobEpilogueFile string `json:"jobEpilogueFile"`

	// JobSettingsFile is ro-bound over ~/.claude/settings.json inside job
	// sandboxes (relaxes the git commit deny so jobs can commit).
	JobSettingsFile string `json:"jobSettingsFile"`

	// JobMaxRuntime is the systemd RuntimeMaxSec for job units, e.g. "6h".
	JobMaxRuntime string `json:"jobMaxRuntime"`

	// SandboxExtraRoBinds are extra host paths bound read-only into sandboxes.
	SandboxExtraRoBinds []string `json:"sandboxExtraRoBinds"`

	// GithubReadOnlyTokenFile is read into GH_TOKEN inside sandboxes.
	GithubReadOnlyTokenFile string `json:"githubReadOnlyTokenFile"`
}

func Load() (*Config, error) {
	cfg := &Config{
		Groups:       map[string][]string{},
		JobTemplates: map[string]JobTemplate{},
	}
	path := os.Getenv("CDGO_CONFIG")
	if path == "" {
		return cfg, nil
	}
	b, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read CDGO_CONFIG: %w", err)
	}
	if err := json.Unmarshal(b, cfg); err != nil {
		return nil, fmt.Errorf("parse CDGO_CONFIG %q: %w", path, err)
	}
	return cfg, nil
}
