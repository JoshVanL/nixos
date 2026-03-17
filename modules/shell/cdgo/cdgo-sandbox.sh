dir="${1:?Usage: __cdgo_sandbox <workspace-dir>}"

if [ ! -d "$dir" ]; then
  echo ">> Error: workspace directory does not exist: $dir" >&2
  exit 1
fi

uid=$(id -u)
home="$HOME"

args=(
  --unshare-all
  --share-net

  # System essentials
  --proc /proc
  --dev /dev
  --tmpfs /tmp

  # Nix store (all tools live here)
  --ro-bind /nix/store /nix/store
  --ro-bind /nix/var /nix/var

  # System binaries and zsh
  --ro-bind /run/current-system /run/current-system

  # Networking and identity
  --ro-bind /etc/resolv.conf /etc/resolv.conf
  --ro-bind /etc/hosts /etc/hosts
  --ro-bind /etc/ssl /etc/ssl
  --ro-bind /etc/static /etc/static
  --ro-bind /etc/passwd /etc/passwd
  --ro-bind /etc/group /etc/group
  --ro-bind /etc/nsswitch.conf /etc/nsswitch.conf
  --ro-bind /etc/profiles /etc/profiles

  # Empty home, then selective mounts on top
  --tmpfs "$home"
)

# Bind home-manager dotfiles (read-only) so zsh, oh-my-zsh, neovim, etc. work.
# Home-manager creates symlinks from $HOME into /nix/store. We resolve the
# home-manager-files store path from .zshrc and ro-bind the entire tree, which
# recreates all managed dotfile symlinks.
# Skip .ssh — handled separately below so known_hosts can be rw.
# Skip .config — handled separately so git config overlay works.
hm_files=$(readlink "$home/.zshrc" 2>/dev/null | sed 's|/\.zshrc$||')
if [ -n "$hm_files" ] && [ -d "$hm_files" ]; then
  while IFS= read -r entry; do
    name=$(basename "$entry")
    case "$name" in
      .ssh|.config|.local) continue ;;
    esac
    args+=(--ro-bind "$entry" "$home/$name")
  done < <(find "$hm_files" -maxdepth 1 -mindepth 1)
  # Bind .config from home-manager, then overlay git config on top
  if [ -d "$hm_files/.config" ]; then
    args+=(--ro-bind "$hm_files/.config" "$home/.config")
  fi
fi

# .local: writable base with home-manager entries (fonts, desktop files) bound ro on top.
# Neovim needs to write to .local/share/nvim and .local/state/nvim.
args+=(--tmpfs "$home/.local")
if [ -n "$hm_files" ] && [ -d "$hm_files/.local" ]; then
  while IFS= read -r entry; do
    rel="${entry#"$hm_files"/}"
    args+=(--ro-bind "$entry" "$home/$rel")
  done < <(find "$hm_files/.local" -maxdepth 3 -not -type d)
fi

# Cache directory (rw) for oh-my-zsh completions, go-build, etc.
if [ -d "$home/.cache" ]; then
  args+=(--bind "$home/.cache" "$home/.cache")
else
  args+=(--dir "$home/.cache")
fi

args+=(
  # The workspace (read-write)
  --bind "$dir" "$dir"
)

# /run/user/$UID: writable tmpfs so neovim can create sockets.
# No SSH agent or other host sockets exposed.
args+=(--tmpfs "/run/user/$uid")

# Claude Code config (read-write for session state)
if [ -e "$home/.claude" ]; then
  args+=(--bind "$home/.claude" "$home/.claude")
fi
if [ -e "$home/.claude.json" ]; then
  args+=(--bind "$home/.claude.json" "$home/.claude.json")
fi

# Go module + build cache (read-only)
if [ -d "$home/go/pkg" ]; then
  args+=(--dir "$home/go" --ro-bind "$home/go/pkg" "$home/go/pkg")
fi

# Extra read-only binds from Nix config
if [ -n "${CDGO_SANDBOX_EXTRA_RO_BINDS:-}" ]; then
  while IFS= read -r path; do
    if [ -n "$path" ] && [ -e "$path" ]; then
      args+=(--ro-bind "$path" "$path")
    fi
  done <<< "$CDGO_SANDBOX_EXTRA_RO_BINDS"
fi

args+=(
  --chdir "$dir"

  --setenv HOME "$home"
  --setenv USER "$(whoami)"
  --setenv CDGO_SANDBOX "1"
  --setenv CDGO_WORKSPACE "$dir"
  --setenv GH_TOKEN "$(cat /persist/etc/github/read-only)"
)

echo ">> Entering sandbox for: $dir" >&2
exec bwrap "${args[@]}" -- /run/current-system/sw/bin/zsh -l
