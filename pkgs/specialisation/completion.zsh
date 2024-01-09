#compdef _specialisation specialisation

function _specialisation() {
  _arguments -C \
    "(-)-q[Print current specialisation]" \
    "(-)-h[Show help]" \
    "1:spec:_specs"
}

function _specs() {
  local -a specs
  specs=( main /nix/var/nix/profiles/system/specialisation/*(N:t) )

  _wanted specs expl 'specialisation' compadd -a specs
}
