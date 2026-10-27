#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

. "$HOME/.local/bin/env"


# Added by Antigravity CLI installer
export PATH="__HOME__/.local/bin:$PATH"

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
case ":$PATH:" in
  *":__HOME__/.ascii/bin:"*) ;;
  *) PATH="__HOME__/.ascii/bin:$PATH" ;;
esac
export PATH
# ASCII BOAT SHELL INTEGRATION END boat
