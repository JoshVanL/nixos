#compdef wp

local -a commands
commands=(
  'fetch:pull candidates from wallhaven into queue'
  'refresh:walk new candidates (1=keep, 2=skip) and prune library'
  'view:browse the library read-only'
  'roll:pick a random wallpaper from library and apply it'
  'current:print the path of the currently applied wallpaper'
  'rm-current:blacklist and delete the current wallpaper, then roll a new one'
  'prune:trim library to WP_LIBRARY_MAX'
  'ls:show library/queue/blacklist counts and paths'
)

_describe 'command' commands
