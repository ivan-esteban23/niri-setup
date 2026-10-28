# niri-setup

Reproducible install of this Arch Linux **Niri + Hyprland + Dux Shell (DMS)** desktop.

```bash
./install.sh --dry-run --no-aur        # preview
TAVILY_API_KEY=tvly-xxxx ./install.sh  # full install (key optional)
./sync-from-system.sh                  # refresh the bundle from the live machine
```

| Option | Effect |
| :--- | :--- |
| `--no-aur` | skip AUR packages / yay bootstrap |
| `--no-system` | skip `/etc` changes and service enabling |
| `--with-hardware` | also install kernel, ucode, firmware, fs tools, zram config |
| `--passwordless-pacman` | create `/etc/sudoers.d/pacman-nopasswd` |
| `--dry-run`, `-y` | preview / no prompt |

- `dotfiles/` is sanitized: `$HOME` → `__HOME__`, API keys → `__TAVILY_API_KEY__`; runtime credentials are excluded.
- Replaced files are backed up to `~/.config-backup-<timestamp>/`.
- Not included: browser/gh/Codex/OpenCode logins, WeChat AppImage, Obsidian vault, wallpapers.

## Custom keybindings

Bound in `dotfiles/config/niri/config.kdl` + `dotfiles/config/niri/dms/binds.kdl`, backed by helper scripts in `dotfiles/local/bin/` and Dux Shell plugins in `dotfiles/config/dms/plugins/`. All of it is rootless.

| Key | Action | Backed by |
| :--- | :--- | :--- |
| `Mod + Alt + D` | DNS Switcher panel | `dnsSwitcher` · `dns-switch` |
| `Mod + Shift + S` / `Mod + Alt + S` | Sudo timer: start / stop (600 min passwordless) | `sudoTimer` · `sudo-timer` |
| `Mod + G` | Install a site as a Brave web app | `webappManager` · `webapp` |
| `Mod + Shift + B` / `Mod + Shift + G` | Image prompt: stage clipboard reference / build ChatGPT prompt | `imgPrompt` · `img-prompt` |
| `Mod + Shift + A` | Capture a region and copy its `@path` for an AI agent | `agent-snip` |
| `Mod + Shift + Space` | Voice dictation (local whisper.cpp) into the focused prompt | `voice-dictate` |
| `Mod + Shift + Return` | AI scratchpad — floating Alacritty running the agent CLI | `alacritty` |
| `Mod + B` | Floating drag-and-drop clipboard shelf | `toggle-drag-shelf` |
| `Mod + V` | Clipboard history modal (text / images / files) | DMS clipboard service · `clipboardHistoryPlus` tile |
| `Mod + Shift + D` | Do Not Disturb, with an on-screen toast | `toggle-dnd` |
| `Mod + S` · `Mod + Shift + M` · `Mod + Alt + W` · `Mod + Alt + T` | LocalSend · VLC · WeChat · rqbit | — |

### DNS Switcher

`Mod + Alt + D` — or the bar pill, which shows the active provider — swaps the system resolver without a password: `nmcli` writes `ipv4.dns`/`ipv6.dns` + `ignore-auto-dns` + `dns-priority 100` on every ethernet/Wi-Fi profile, and Tailscale's `--accept-dns` is re-toggled so it writes `/etc/resolv.conf` **last** (a late NetworkManager update otherwise clobbers MagicDNS).

| Provider | IPv4 | IPv6 |
| :--- | :--- | :--- |
| Google | `8.8.8.8` `8.8.4.4` | `2001:4860:4860::8888` `2001:4860:4860::8844` |
| Cloudflare | `1.1.1.1` `1.0.0.1` | `2606:4700:4700::1111` `2606:4700:4700::1001` |
| Quad9 | `9.9.9.9` `149.112.112.112` | `2620:fe::fe` `2620:fe::9` |
| Tailscale MagicDNS | `100.100.100.100` | `fd7a:115c:a1e0::53` |
| ISP / router (DHCP) | no overrides, MagicDNS off | — |

- **Bar pill id**: DankBar lists plugin widgets by the **bare plugin id** — `"dnsSwitcher"` in `dotfiles/config/dms/settings.json` → `barConfigs[].rightWidgets`. The `plugin_` prefix is Control-Center-only and fails silently in the bar. The `settings` IPC rejects array values, so bar layout edits go straight into that file, then `dms restart`.
- glibc reads only the first **3** nameservers, so the panel flags the 4th as ignored.
- Joining a new Wi-Fi network gives that profile no override, so the resolver and the profiles disagree → the card turns amber; press **Re-apply**.
- Terminal: `dns-switch status | current | providers | apply <provider> | cycle | test` (state in `~/.cache/dns-switch/state.json`).
