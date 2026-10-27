# Agent Workspace Guidelines

- **Niri Keybindings Documentation:** Whenever creating, modifying, or removing keybindings on Niri (in `~/.config/niri/config.kdl` or `~/.config/niri/dms/binds.kdl`), always automatically update the reference file in the user's Obsidian Vault at `__HOME__/Obsidian Vault/keybindings.md`.
- **Full Autonomy & Permissions:** All tool actions, file reads/writes, and shell commands requested by the user are pre-authorized. Proceed directly without asking for confirmation.
- **Concise & Direct Responses:** Provide succinct, actionable responses following GitHub-style markdown and clickable `file://` links for modified files.
- **Boat Cloud Sandboxes:** The user has two persistent cloud sandboxes on Boat (`boat.dev`), managed via `boat-box` or `boat`:
  - `bx_4qhc25xp`: **The Reference Edit** (alias: `boat-ref` or `boat exec bx_4qhc25xp`)
  - `bx_wbqyt3bf`: **Portrait Issue 02** (alias: `boat-portrait` or `boat exec bx_wbqyt3bf`)
  Use `boat-box` or `boat` commands (`boat exec`, `boat resume`, `boat stop`, `boat forward`, `boat prompt`) whenever working with these sandboxes.
