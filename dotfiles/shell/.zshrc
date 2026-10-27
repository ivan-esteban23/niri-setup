
. "$HOME/.local/bin/env"


# Added by Antigravity CLI installer
export PATH="__HOME__/.local/bin:$HOME/.opencode/bin:$PATH"

# Agentic mode: agy & qoder run with full auto-approve permissions
alias agy='agy --dangerously-skip-permissions'
alias qoder='qodercli --dangerously-skip-permissions'
alias qodercli='qodercli --dangerously-skip-permissions'

# Qoder Model Shortcuts
alias qoder-qwen='qodercli -m Qwen3.8-Flash --reasoning-effort xhigh --dangerously-skip-permissions'
alias qoder-deepseek='qodercli -m DeepSeek-Flash --reasoning-effort high --dangerously-skip-permissions'
export TAVILY_API_KEY="__TAVILY_API_KEY__"

# Experiential Labs API Key
export EXPERIENTIALLABS_API_KEY="__EXPERIENTIALLABS_API_KEY__"
export EXPLABS_API_KEY="__EXPERIENTIALLABS_API_KEY__"

# Boat Sandboxes
export BOAT_REF="bx_4qhc25xp"
export BOAT_PORTRAIT="bx_wbqyt3bf"
alias boat-ref='boat exec bx_4qhc25xp --cwd Work/the-reference-edit'
alias boat-portrait='boat exec bx_wbqyt3bf --cwd Work/the-portrait-edit-issue-02'
alias boat-ref-ssh='boat ssh bx_4qhc25xp'
alias boat-portrait-ssh='boat ssh bx_wbqyt3bf'
