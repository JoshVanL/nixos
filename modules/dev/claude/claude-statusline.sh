input=$(cat) || input="{}"

raw_cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""' 2>/dev/null) || raw_cwd=""
home_dir="$HOME"
short_cwd="${raw_cwd/#$home_dir/\~}"
[ -z "$short_cwd" ] && short_cwd="~"

git_info=""
if [ -n "$raw_cwd" ] && git_branch=$(git --no-optional-locks -C "$raw_cwd" symbolic-ref --short HEAD 2>/dev/null); then
  git_status=$(git --no-optional-locks -C "$raw_cwd" status --porcelain 2>/dev/null)
  git_dirty=""
  if echo "$git_status" | grep -qv '^\?\?'; then
    git_dirty="*"
  elif [ -n "$git_status" ]; then
    git_dirty="?"
  fi
  git_info=" - ${git_branch}${git_dirty}"
fi

model=$(echo "$input" | jq -r '.model.display_name // ""' 2>/dev/null) || model=""

used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty' 2>/dev/null) || used_pct=""
ctx_info=""
if [ -n "$used_pct" ]; then
  used_int=$(printf "%.0f" "$used_pct" 2>/dev/null) || used_int="$used_pct"
  ctx_info=" - ctx:${used_int}%"
fi

c139='\033[38;5;139m'
c245='\033[38;5;245m'
c250='\033[38;5;250m'
reset='\033[0m'

line="${c139}${short_cwd}${c250}${git_info} - ${c245}${model}${ctx_info}${c250} - $(whoami).$(hostname -s)${reset}"
printf '%b' "$line"
