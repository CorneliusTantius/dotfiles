#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Case-insensitive tab completion and globbing
bind 'set completion-ignore-case on'
shopt -s nocaseglob

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ..='cd ..'
PS1='[\u@\h \W]\$ '
export PATH="$HOME/.local/bin:$PATH"
