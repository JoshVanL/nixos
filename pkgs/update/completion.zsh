#compdef _update update

function _update() {
  _arguments -C "1:update:_update"
}

function _update() {
  local -a update
  specs=( main /nix/var/nix/profiles/system/specialisation/*(N:t) )

  _wanted specs expl 'update' compadd -a specs
}
