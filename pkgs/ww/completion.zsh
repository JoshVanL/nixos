#compdef _ww ww

function _ww() {
  local commands
  commands=( ${(f)"$(whence -wm '*' 2>/dev/null | sed 's/:[^:]*$//')"} )
  _wanted commands expl 'available commands' compadd -- $commands
}
