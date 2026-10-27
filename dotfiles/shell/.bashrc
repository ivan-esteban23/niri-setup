# ASCII BOAT SHELL INTEGRATION START boat
case ":$PATH:" in
  *":__HOME__/.ascii/bin:"*) ;;
  *) PATH="__HOME__/.ascii/bin:$PATH" ;;
esac
export PATH
# ASCII BOAT SHELL INTEGRATION END boat

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

# Experiential Labs API Key
export EXPERIENTIALLABS_API_KEY="__EXPERIENTIALLABS_API_KEY__"
export EXPLABS_API_KEY="__EXPERIENTIALLABS_API_KEY__"

# QODER_DISPATCHER_PATH v1
_qoder_dispatcher_entry="$HOME/.qoder/entry"
_qoder_dispatcher_rest=${PATH-}
_qoder_dispatcher_tail=
while :; do
  case $_qoder_dispatcher_rest in
    *:*) _qoder_dispatcher_part=${_qoder_dispatcher_rest%%:*}; _qoder_dispatcher_rest=${_qoder_dispatcher_rest#*:}; _qoder_dispatcher_more=1 ;;
    *) _qoder_dispatcher_part=$_qoder_dispatcher_rest; _qoder_dispatcher_more= ;;
  esac
  if [ "$_qoder_dispatcher_part" != "$_qoder_dispatcher_entry" ]; then
    _qoder_dispatcher_tail="${_qoder_dispatcher_tail}:${_qoder_dispatcher_part}"
  fi
  [ -n "$_qoder_dispatcher_more" ] || break
done
PATH="${_qoder_dispatcher_entry}${_qoder_dispatcher_tail}"
export PATH
unset _qoder_dispatcher_entry _qoder_dispatcher_rest _qoder_dispatcher_tail _qoder_dispatcher_part _qoder_dispatcher_more
# END QODER_DISPATCHER_PATH v1

# ASCII BOAT SHELL INTEGRATION START boat
boat() {
  current_file=$(mktemp)
  convo_file=$(mktemp)
  old_current_file=${BOAT_CURRENT_ID_FILE-}
  old_convo_file=${BOAT_CURRENT_CONVO_FILE-}
  export BOAT_CURRENT_ID_FILE="$current_file"
  export BOAT_CURRENT_CONVO_FILE="$convo_file"
  command "__HOME__/.ascii/bin/boat" "$@"
  boat_status=$?
  if [ "$boat_status" -eq 0 ]; then
    case "${1:-}" in
      new|start|fork)
        if [ -s "$current_file" ]; then
          current_id=$(tr -d '[:space:]' < "$current_file")
          if [ -n "$current_id" ]; then export BOAT_CURRENT_ID="$current_id"; fi
        fi
        ;;
    esac
    case "${1:-}" in
      prompt)
        if [ -s "$convo_file" ]; then
          IFS= read -r current_convo < "$convo_file" || current_convo=""
          if [ -n "$current_convo" ]; then export BOAT_CURRENT_CONVO="$current_convo"; fi
        fi
        ;;
    esac
  fi
  if [ -n "$old_current_file" ]; then export BOAT_CURRENT_ID_FILE="$old_current_file"; else unset BOAT_CURRENT_ID_FILE; fi
  if [ -n "$old_convo_file" ]; then export BOAT_CURRENT_CONVO_FILE="$old_convo_file"; else unset BOAT_CURRENT_CONVO_FILE; fi
  rm -f "$current_file" "$convo_file"
  return "$boat_status"
}
# ASCII BOAT SHELL INTEGRATION END boat

# Boat Sandboxes
export BOAT_REF="bx_4qhc25xp"
export BOAT_PORTRAIT="bx_wbqyt3bf"
alias boat-ref='boat exec bx_4qhc25xp --cwd Work/the-reference-edit'
alias boat-portrait='boat exec bx_wbqyt3bf --cwd Work/the-portrait-edit-issue-02'
alias boat-ref-ssh='boat ssh bx_4qhc25xp'
alias boat-portrait-ssh='boat ssh bx_wbqyt3bf'
