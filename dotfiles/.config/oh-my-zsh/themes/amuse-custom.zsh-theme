# vim:ft=zsh ts=2 sw=2 sts=2

rvm_current() {
  rvm current 2>/dev/null
}

rbenv_version() {
  rbenv version 2>/dev/null | awk '{print $1}'
}

source /etc/nixos/dotfiles/.config/oh-my-zsh/themes/kubectl.zsh

PROMPT='%{%F{250}%}%n %{%F{250}%}% %{%F{139}%}${PWD/#$HOME/~}%{$reset_color%}$(git_prompt_info) %{%F{250}%}% - %{%F{250}%}% %? %{%F{250}%}% - %{%F{245}%}%*%{%F{255}%} - $ZSH_KUBECTL_PROMPT
$ '

# Must use Powerline font, for \uE0A0 to render.
ZSH_THEME_GIT_PROMPT_PREFIX="%{%F{250}%}%  - %{%F{250}%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="*"
ZSH_THEME_GIT_PROMPT_UNTRACKED="?"
ZSH_THEME_GIT_PROMPT_CLEAN=""

if [ -e ~/.rvm/bin/rvm-prompt ]; then
  RPROMPT='%{$fg_bold[red]%}‹$(rvm_current)›%{$reset_color%}'
else
  if which rbenv &> /dev/null; then
    RPROMPT='%{$fg_bold[red]%}$(rbenv_version)%{$reset_color%}'
  fi
fi
