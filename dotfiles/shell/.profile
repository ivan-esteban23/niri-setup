
. "$HOME/.local/bin/env"


# Added by Antigravity CLI installer
export PATH="__HOME__/.local/bin:$HOME/.opencode/bin:$PATH"

# Tavily API Key
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
