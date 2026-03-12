{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.shell.cdgo;

  cdgoSH = pkgs.writeShellApplication {
    name = "__cdgo";
    runtimeInputs = with pkgs; [ git gh jq coreutils ];
    text = ''
      if [ -z "''${1:-}" ]; then
        echo "Usage: cdgo <name> [owner/repo ...]" >&2
        exit 1
      fi

      name="$1"
      shift

      dir="$HOME/sandbox/workspace/$name"
      mkdir -p "$dir"

      # Clone repos
      for repo in "$@"; do
        owner="''${repo%%/*}"
        reponame="''${repo##*/}"
        repodir="$dir/$reponame"

        if [ -d "$repodir" ]; then
          echo "Skipping $repo: $repodir already exists" >&2
          continue
        fi

        echo "Cloning $repo..." >&2
        git clone --depth 1 "git@github.com:''${repo}.git" "$repodir"

        if [ "$owner" != "joshvanl" ]; then
          git -C "$repodir" remote add fork "git@github.com:joshvanl/''${reponame}.git"
        fi
      done

      # Write .claude/settings.json if it doesn't exist
      mkdir -p "$dir/.claude"
      if [ ! -f "$dir/.claude/settings.json" ]; then
      cat > "$dir/.claude/settings.json" << 'SETTINGS'
      {
        "permissions": {
          "allow": [
            "Bash(git:*)",
            "Bash(gh:*)",
            "Bash(nix:*)",
            "Bash(make:*)",
            "Bash(go:*)",
            "Bash(cargo:*)",
            "Bash(rustc:*)",
            "Bash(python:*)",
            "Bash(python3:*)",
            "Bash(node:*)",
            "Bash(npm:*)",
            "Bash(npx:*)",
            "WebSearch",
            "WebFetch"
          ],
          "deny": [
            "Bash(git push:*)",
            "Bash(git push)",
            "Bash(gh pr create:*)",
            "Bash(gh pr merge:*)",
            "Bash(gh release:*)",
            "Bash(gh repo create:*)",
            "Bash(gh issue create:*)"
          ]
        }
      }
      SETTINGS
      fi

      # Write CLAUDE.md if it doesn't exist
      if [ ! -f "$dir/CLAUDE.md" ]; then
      cat > "$dir/CLAUDE.md" << 'CLAUDEMD'
      When making git commits, ALWAYS use `git commit -s` (signoff flag).
      NEVER push to any remote (origin, fork, or any other).
      NEVER create, merge, or comment on pull requests or issues on GitHub.
      NEVER create releases or repositories on GitHub.
      CLAUDEMD
      fi

      # Print the directory path for the shell function wrapper
      echo "$dir"
    '';
  };

in {
  options.me.shell.cdgo = {
    enable = mkEnableOption "cdgo";
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.me.username} = {
      home.packages = [ cdgoSH ];

      programs.zsh.initContent = ''
        cdgo() { cd "$(__cdgo "$@")" || return; }
      '';
    };
  };
}
