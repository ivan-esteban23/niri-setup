#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

. "$HOME/.local/bin/env"


# Added by Antigravity CLI installer
export PATH="__HOME__/.local/bin:$HOME/.opencode/bin:$PATH"

# Agentic mode: agy runs with full auto-approve permissions
alias agy='agy --dangerously-skip-permissions'

# Tavily API Key
export TAVILY_API_KEY="__TAVILY_API_KEY__"
