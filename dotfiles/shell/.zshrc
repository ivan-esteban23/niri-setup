# ~/.zshrc - Modern Zsh Configuration

# ---------------------------------------------------------
# 1. Environment & PATH
# ---------------------------------------------------------
export EDITOR='nvim'
export VISUAL='nvim'

# Sourcing local environment if available
if [ -f "$HOME/.local/bin/env" ]; then
  . "$HOME/.local/bin/env"
fi

# ASCII Boat Shell Integration
case ":$PATH:" in
  *":__HOME__/.ascii/bin:"*) ;;
  *) PATH="__HOME__/.ascii/bin:$PATH" ;;
esac
export PATH

# Antigravity CLI & Opencode
export PATH="__HOME__/.local/bin:$HOME/.opencode/bin:$PATH"

# Qoder Dispatcher
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

# API Keys
export TAVILY_API_KEY="__TAVILY_API_KEY__"
export EXPERIENTIALLABS_API_KEY="__EXPERIENTIALLABS_API_KEY__"
export EXPLABS_API_KEY="__EXPERIENTIALLABS_API_KEY__"

# ---------------------------------------------------------
# 2. History Settings
# ---------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

setopt EXTENDED_HISTORY          # Write history in ':start:elapsed;command' format
setopt SHARE_HISTORY             # Share history across sessions
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate event first when trimming
setopt HIST_IGNORE_DUPS          # Don't record duplicate sequential entry
setopt HIST_IGNORE_ALL_DUPS      # Delete old duplicate entry
setopt HIST_FIND_NO_DUPS         # Do not display already found duplicate
setopt HIST_IGNORE_SPACE         # Ignore command lines starting with space
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries to disk
setopt HIST_REDUCE_BLANKS        # Remove extra blanks from commands
setopt INC_APPEND_HISTORY        # Write history immediately

# Shell Options
setopt AUTO_CD                   # Type folder name directly to cd
setopt CORRECT                   # Auto-correct misspelled commands
setopt INTERACTIVE_COMMENTS      # Allow '#' comments in interactive shell

# ---------------------------------------------------------
# 3. Completions & FZF-Tab
# ---------------------------------------------------------
fpath=(/usr/share/zsh/site-functions $fpath)
autoload -Uz compinit
compinit -C

# Completion styling
zstyle ':completion:*' menu no
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Load fzf-tab (interactive fuzzy tab completions)
if [ -f "$HOME/.zsh/plugins/fzf-tab/fzf-tab.plugin.zsh" ]; then
  source "$HOME/.zsh/plugins/fzf-tab/fzf-tab.plugin.zsh"
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath 2>/dev/null'
  zstyle ':fzf-tab:complete:*:*' fzf-preview 'bat --color=always --line-range :300 $realpath 2>/dev/null || eza -1 --color=always $realpath 2>/dev/null'
  zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-headers -w -w'
  zstyle ':fzf-tab:complete:kill:argument-rest' fzf-flags '--preview-window=down:3:wrap'
fi

# ---------------------------------------------------------
# 4. FZF & Zoxide (Searching & Navigation)
# ---------------------------------------------------------
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix --hidden --follow --exclude .git'

export FZF_DEFAULT_OPTS="
  --height 50%
  --layout=reverse
  --border
  --inline-info
  --preview-window=right:60%:border-left
"

export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :300 {} 2>/dev/null || eza --tree --level=2 --color=always {} 2>/dev/null'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always {} 2>/dev/null'"
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'"

# Source FZF shell integration (Ctrl+R, Ctrl+T, Alt+C)
if command -v fzf &>/dev/null; then
  eval "$(fzf --zsh)"
fi

# Source Zoxide (smart cd: z <path>, zi <fzf-jump>)
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi

# ---------------------------------------------------------
# 5. Git & Lazygit (TUI + Delta Pager)
# ---------------------------------------------------------
if command -v lazygit &>/dev/null; then
  alias lg='lazygit'

  # Ctrl+G: Open Lazygit in-place
  lazygit-widget() {
    lazygit < /dev/tty
    zle -R
  }
  zle -N lazygit-widget
  bindkey '^G' lazygit-widget
fi

# ---------------------------------------------------------
# 6. Yazi Terminal File Manager
# ---------------------------------------------------------
if command -v yazi &>/dev/null; then
  # 'y' wrapper changes directory upon quitting yazi
  y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
      builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
  }
fi

# ---------------------------------------------------------
# 7. Direnv (Per-directory automatic environment loader)
# ---------------------------------------------------------
if command -v direnv &>/dev/null; then
  eval "$(direnv hook zsh)"
fi

# ---------------------------------------------------------
# 8. Interactive Search & Productivity Functions
# ---------------------------------------------------------

# zp: Fuzzy jump to any recent project and open it immediately in Neovim
zp() {
  local target
  target=$(zoxide query -l | fzf --prompt="Open Project in Neovim > " \
    --preview='eza --tree --level=2 --icons --color=always {} 2>/dev/null')
  if [ -n "$target" ]; then
    cd "$target" && ${EDITOR:-nvim} .
  fi
}

# rgi: Real-time interactive ripgrep with fzf + bat preview (Press Enter to edit at matching line)
rgi() {
  local INITIAL_QUERY="${*:-}"
  local RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case "
  FZF_DEFAULT_COMMAND="$RG_PREFIX $(printf %q "$INITIAL_QUERY")" \
  fzf --bind "change:reload:$RG_PREFIX {q} || true" \
      --ansi --phony --query "$INITIAL_QUERY" \
      --height=85% --layout=reverse \
      --delimiter : \
      --preview 'bat --color=always --highlight-line {2} {1}' \
      --preview-window 'right,60%,border-left,+{2}+3/3,~3' \
      --bind 'enter:become(${EDITOR:-nvim} {1} +{2})'
}

# fif: Fuzzy search inside files matching pattern
fif() {
  if [ -z "$1" ]; then
    echo "Usage: fif <pattern>"
    return 1
  fi
  rg --files-with-matches --no-messages "$1" | fzf --preview "bat --color=always --style=numbers {} 2>/dev/null"
}

# fe: Fuzzy edit file in Neovim
fe() {
  local file
  file=$(fd --type f --hidden --exclude .git | fzf --preview 'bat --color=always --style=numbers {} 2>/dev/null')
  if [ -n "$file" ]; then
    ${EDITOR:-nvim} "$file"
  fi
}

# fkill: Interactive process kill
fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m --header='[Select process to kill]' | awk '{print $2}')
  if [ -n "$pid" ]; then
    echo "$pid" | xargs kill -${1:-9}
  fi
}

# extract (x): Universal archive extractor
extract() {
  if [ -z "$1" ]; then
    echo "Usage: extract <archive_file>"
    return 1
  fi
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2)   tar xjf "$1"        ;;
      *.tar.gz)    tar xzf "$1"        ;;
      *.bz2)       bunzip2 "$1"        ;;
      *.rar)       unrar x "$1"        ;;
      *.gz)        gunzip "$1"         ;;
      *.tar)       tar xf "$1"         ;;
      *.tbz2)      tar xjf "$1"        ;;
      *.tgz)       tar xzf "$1"        ;;
      *.zip)       unzip "$1"          ;;
      *.Z)         uncompress "$1"     ;;
      *.7z)        7z x "$1"           ;;
      *.tar.xz)    tar xJf "$1"        ;;
      *.tar.zst)   tar --zstd -xf "$1" ;;
      *)           echo "'$1' cannot be extracted via extract" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}
alias x='extract'

# gwt: Parallel Agent Git Worktrees
gwt() {
  local subcmd="${1:-}"
  if [ -z "$subcmd" ]; then
    echo "Usage: gwt <command> [args]"
    echo "Commands:"
    echo "  new <branch>     Create a worktree in ../worktrees/<repo>-<branch>"
    echo "  agy <branch>     Create a worktree and immediately launch agy in it"
    echo "  cd               Fuzzy-select a worktree and cd into it"
    echo "  ls               List active worktrees"
    echo "  rm <branch>      Remove a worktree safely"
    return 1
  fi

  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ -z "$git_root" ]; then
    echo "Error: Not inside a git repository."
    return 1
  fi
  local repo_name=$(basename "$git_root")
  local worktree_base="$(dirname "$git_root")/worktrees"

  case "$subcmd" in
    ls|list)
      git worktree list
      ;;
    new)
      local branch="$2"
      if [ -z "$branch" ]; then echo "Usage: gwt new <branch>"; return 1; fi
      mkdir -p "$worktree_base"
      local dest="$worktree_base/${repo_name}-${branch}"
      git worktree add -b "$branch" "$dest" || git worktree add "$dest" "$branch"
      echo "Worktree created at: $dest"
      cd "$dest"
      ;;
    agy)
      local branch="$2"
      if [ -z "$branch" ]; then echo "Usage: gwt agy <branch>"; return 1; fi
      mkdir -p "$worktree_base"
      local dest="$worktree_base/${repo_name}-${branch}"
      git worktree add -b "$branch" "$dest" 2>/dev/null || git worktree add "$dest" "$branch" 2>/dev/null || true
      echo "Launching Antigravity agent in worktree: $dest"
      (cd "$dest" && agy)
      ;;
    cd)
      local selected
      selected=$(git worktree list | fzf --prompt="Select worktree > " | awk '{print $1}')
      if [ -n "$selected" ]; then
        cd "$selected"
      fi
      ;;
    rm)
      local target="$2"
      if [ -z "$target" ]; then echo "Usage: gwt rm <branch_or_path>"; return 1; fi
      git worktree remove "$target"
      ;;
    *)
      echo "Unknown gwt command: $subcmd"
      return 1
      ;;
  esac
}

# ---------------------------------------------------------
# 9. AI Workflows & Cloud Sandboxes
# ---------------------------------------------------------
# Agentic mode: agy & qoder run with full auto-approve permissions
alias agy='agy --dangerously-skip-permissions'
alias qoder='qodercli --dangerously-skip-permissions'
alias qodercli='qodercli --dangerously-skip-permissions'

# Qoder Model Shortcuts
alias qoder-qwen='qodercli -m Qwen3.8-Flash --reasoning-effort xhigh --dangerously-skip-permissions'
alias qoder-deepseek='qodercli -m DeepSeek-Flash --reasoning-effort high --dangerously-skip-permissions'

# ---------------------------------------------------------
# 10. Modern CLI Replacements & Aliases
# ---------------------------------------------------------
if command -v eza &>/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -lh --icons --git --group-directories-first'
  alias la='eza -lha --icons --git --group-directories-first'
  alias lt='eza --tree --level=2 --icons'
else
  alias ls='ls --color=auto'
  alias ll='ls -lh'
  alias la='ls -lha'
fi

if command -v bat &>/dev/null; then
  alias cat='bat --paging=never'
fi

alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# ---------------------------------------------------------
# 11. Ergonomic Plugins & Keybindings
# ---------------------------------------------------------
# zsh-autopair (Auto-close quotes and brackets)
if [ -f "$HOME/.zsh/plugins/zsh-autopair/autopair.zsh" ]; then
  source "$HOME/.zsh/plugins/zsh-autopair/autopair.zsh"
  autopair-init
fi

# zsh-you-should-use (Reminds you of your aliases)
if [ -f "$HOME/.zsh/plugins/zsh-you-should-use/you-should-use.plugin.zsh" ]; then
  source "$HOME/.zsh/plugins/zsh-you-should-use/you-should-use.plugin.zsh"
fi

# Autosuggestions (Fish-like)
if [ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
  bindkey '^ ' autosuggest-accept       # Ctrl+Space to accept suggestion
  bindkey '^E' autosuggest-accept       # Ctrl+E to accept suggestion
fi

# History substring search (Up/Down arrow prefix matching)
if [ -f /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ]; then
  source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
  bindkey -M vicmd 'k' history-substring-search-up
  bindkey -M vicmd 'j' history-substring-search-down
fi

# Syntax Highlighting (MUST be loaded after other syntax plugins)
if [ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# ---------------------------------------------------------
# 12. Long-Running Command Notification Toast (>15s)
# ---------------------------------------------------------
_notify_preexec() {
  _CMD_START_TIME=$SECONDS
  _LAST_CMD="$1"
}

_notify_precmd() {
  local exit_code=$?
  if [ -n "$_CMD_START_TIME" ]; then
    local elapsed=$(( SECONDS - _CMD_START_TIME ))
    unset _CMD_START_TIME

    if [ $elapsed -ge 15 ]; then
      case "$_LAST_CMD" in
        nvim*|vim*|nano*|man*|less*|yazi*|lazygit*|lg*|top*|htop*|btop*|cava*)
          return
          ;;
      esac

      local cmd_short="${_LAST_CMD:0:50}"
      if [ $exit_code -eq 0 ]; then
        notify-send -u normal -a "Zsh" -i terminal \
          "✔ Task Completed (${elapsed}s)" \
          "$cmd_short" 2>/dev/null || true
      else
        notify-send -u critical -a "Zsh" -i error \
          "✘ Task Failed (exit $exit_code in ${elapsed}s)" \
          "$cmd_short" 2>/dev/null || true
      fi
    fi
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _notify_preexec
add-zsh-hook precmd _notify_precmd

# ---------------------------------------------------------
# 13. Starship Prompt
# ---------------------------------------------------------
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi
