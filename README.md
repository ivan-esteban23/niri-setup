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
- Replaced files are backed up to `~/.config-backup-<timestamp>/`. Re-running the installer replaces bundled configuration files, including DMS settings; review your backup to restore any local customizations.
- When a Tavily key is supplied, the installer preserves other Gemini MCP servers and backs up the previous MCP configuration. Invalid existing MCP JSON is left unchanged with a warning.
- Not included: browser/gh/Codex/OpenCode logins, WeChat AppImage, Obsidian vault, wallpapers.

## Reminders

The **Reminders** DMS plugin offers quick 5-, 15-, 30- and 60-minute reminders, an optional local date and time (`YYYY-MM-DD HH:MM`), a scrollable list, completion, deletion and a 10-minute snooze. Enable or add the Reminders widget in DMS's plugin/widget settings to use it from the control center or bar. Its accent follows the current DMS theme.

Reminders are stored locally in `${XDG_DATA_HOME:-~/.local/share}/niri-reminders/`. The user timer `niri-reminders.timer` checks once per minute and retries overdue notifications when the notification service is unavailable. The standard installer enables the timer; after installing with `--no-system`, enable it after logging in with `systemctl --user enable --now niri-reminders.timer`. Notifications require an active user session and notification service; the computer does not wake itself or send alerts while powered off. Overdue items are delivered when the timer and notification service are available again. The timing follows the machine's local timezone.

The command also works independently of the panel:

```bash
niri-reminders add "Take a break" --in 15
niri-reminders add "Call the studio" --at "2026-12-01 14:30"
niri-reminders list
niri-reminders snooze REMINDER_ID 10
niri-reminders done REMINDER_ID
niri-reminders delete REMINDER_ID
```

Run the offline backend checks with `python3 -m unittest discover -s tests -v`.

## Theme Switcher

The **Theme Switcher** DMS plugin provides Tokyo Night, Dracula, Catppuccin Mocha, Macchiato and Frappé, plus Gruvbox Dark, Astral, Aurora, Eldritch, Monokai and Moodpeak, and warm Gruvbox Light, Solarized Light and Rosé Pine Dawn. Each row previews its background and accent; the check mark shows the selected palette. The light options use cream, sand and muted rose surfaces instead of pure-white backgrounds.

A fresh `./install.sh` installation copies and enables the plugin with the other DMS configuration. On an existing setup, first review the installer's backup and overwrite behavior; to install just this plugin, copy `dotfiles/config/dms/plugins/themeSwitcher` to `~/.config/dms/plugins/`, then enable **Theme Switcher** in DMS plugin settings and add it to the control center or bar. Reload DMS if it does not discover the plugin. Select a palette in its panel; use DMS theme settings to return to another custom, stock or wallpaper-derived theme. No keyboard shortcut is added.

The switcher uses DMS custom-theme and light/dark settings. DMS may regenerate its configured application theme files when a palette changes; which applications follow it depends on the DMS integration and templates enabled on your machine. Existing app-specific themes are not guaranteed to change. An automatic DMS light/dark schedule can later change the mode. Theme appearance, keyboard navigation and application integrations still need verification in a real DMS/Niri session.

Palette colors are adapted for DMS roles from upstream sources: [Tokyo Night](https://github.com/folke/tokyonight.nvim) (Apache-2.0), [Dracula](https://github.com/dracula/dracula-theme) (MIT), [Catppuccin](https://github.com/catppuccin/palette) (MIT), [Gruvbox](https://github.com/morhetz/gruvbox), [Solarized](https://github.com/altercation/solarized) (MIT), and [Rosé Pine](https://github.com/rose-pine/rose-pine-palette) (MIT). Additional palette references: [Astral](https://github.com/brmnl/omarchy-astral-theme), [Aurora](https://github.com/thevideinfra/omarchy-aurora-theme), [Eldritch](https://github.com/eldritch-theme/omarchy), [Monokai](https://github.com/bjarneo/omarchy-monokai-theme), and [Moodpeak](https://github.com/HANCORE-linux/omarchy-moodpeak-theme), listed by [Omarchy](https://omarchy.org/themes/). These are palette adaptations, not copies of the projects' plugins; some role colors are adjusted for readability. Run `python3 -m unittest discover -s tests -v` for offline palette and reminder checks.

## Custom keybindings

Bound in `dotfiles/config/niri/config.kdl` + `dotfiles/config/niri/dms/binds.kdl`, backed by helper scripts in `dotfiles/local/bin/` and Dux Shell plugins in `dotfiles/config/dms/plugins/`. All of it is rootless.

| Key | Action | Backed by |
| :--- | :--- | :--- |
| `Mod + Alt + D` | DNS Switcher panel (open-only, not a toggle) | `dnsSwitcher` · `dns-switch` |
| `Mod + Alt + M` | Open the Reminders panel | `reminders` · `niri-reminders` |
| `Mod + Ctrl + T` | Open the Theme Switcher panel | `themeSwitcher` |
| `Mod + Shift + S` / `Mod + Alt + S` | Sudo timer: start / stop (600 min passwordless) | `sudoTimer` · `sudo-timer` |
| `Mod + G` | Install a site as a Brave web app | `webappManager` · `webapp` |
| `Mod + Shift + B` / `Mod + Shift + G` | Image prompt: stage clipboard reference / build ChatGPT prompt | `imgPrompt` · `img-prompt` |
| `Mod + Shift + A` | Capture a region and copy its `@path` for an AI agent | `agent-snip` |
| `Mod + Shift + Space` | Voice dictation (local whisper.cpp) into the focused prompt | `voice-dictate` |
| `Mod + Shift + Return` | AI scratchpad — floating Alacritty running the agent CLI | `alacritty` |
| `Mod + Alt + Return` | Plain scratchpad — floating Alacritty, your shell, no agent CLI | `alacritty` |
| `Mod + Ctrl + Return` | foot scratchpad — floating `foot`, no AI CLI at all | `foot` |
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

### Synthetic input (ydotool)

`ydotool` drives `/dev/uinput` to press real keys (used to verify bindings end-to-end — `wtype` cannot hold modifiers on this compositor). Three pieces, all unprivileged:

- `dotfiles/etc/udev/rules.d/72-uinput-uaccess.rules` — `TAG+="uaccess"` on `/dev/uinput`, so logind ACLs the active seat user in (no `input` group, which would expose every keyboard/mouse device). **Must sort before `73-seat-late.rules`**: that file runs the `uaccess` builtin only for tags already present, so a `99-` rule silently grants nothing.
- `dotfiles/systemd-user/ydotoold.service` — user service, `--socket-path=%t/ydotool.sock --socket-perm=0600`, `WantedBy=niri.service`.
- `dotfiles/config/environment.d/50-ydotool.conf` — `YDOTOOL_SOCKET=${XDG_RUNTIME_DIR}/ydotool.sock` for clients (the upstream default `/tmp/.ydotool_socket` is world-writable).

```bash
ydotool key 125:1 56:1 32:1 32:0 56:0 125:0   # Super_L + Alt_L + D (evdev codes)
```

## AI Agents bar widget

The AI Agents bar pill opens a panel with Codex subscription rate-limit windows, percentages used and reset times. It refreshes every five minutes and offers a manual refresh. The `codex` CLI must be installed and signed in to a supported ChatGPT subscription; API-key billing and other providers may not report subscription limits. Errors and unavailable limits are shown in the panel. The widget uses the local Codex app-server and does not read or store credentials itself. Antigravity usage comes from the most recently updated local-mode cache of the Antigravity Cockpit extension (`~/.antigravity_cockpit/cache/quota_v2/local`); install the extension and run local monitoring to populate it. The panel shows the snapshot age and does not access credentials or request a refresh from Cockpit. With multiple accounts it shows the newest snapshot without identifying the account. Claude, Grok, account management and cross-device aggregation are not yet supported.

A fresh installation copies and enables the plugin and adds `aiAgents` to the bar. On an existing setup, review the installer's backup and overwrite behavior before updating; alternatively copy `dotfiles/config/dms/plugins/aiAgents` to `~/.config/dms/plugins/` and `dotfiles/local/bin/ai-agent-usage` to `~/.local/bin/`, replace `__HOME__` in the QML with your home path, enable the plugin, and add `aiAgents` to the bar in DMS settings. Reload DMS as needed. The panel requires a real DMS session for visual verification.

## Google Calendar bar widget

The **Google Calendar** pill shows the next timed event within 12 hours. Open it for the next three days, Google Meet links and event details; **Sync now** refreshes the agenda. The widget polls every 30 seconds, fetches at most every five minutes, and sends a desktop notification two minutes before a timed event. Notifications require DMS and the notification service to be running; all-day events do not trigger reminders. After a failed sync, the panel labels previously cached events as cached.

To connect your account on your own computer:

1. Install `gcalcli` 4.5 or newer using your package manager or `pipx install gcalcli`.
2. Enable the Google Calendar API in Google Cloud, configure the OAuth consent screen, and create a **Desktop app** OAuth client. If the app is in testing, add your account as a test user. Workspace accounts may require administrator approval.
3. Run `umask 077; gcalcli init` in a terminal and follow its prompts to provide your OAuth client details and sign in. Google may require renewed authorization depending on the app's publishing status.
4. Install or update this bundle, enable **Google Calendar** in DMS if needed, and reload DMS. A fresh installation adds `googleCalendar` to the bar. Existing installations should review the installer's backup and overwrite behavior; alternatively copy `dotfiles/config/dms/plugins/googleCalendar` to `~/.config/dms/plugins/`, replace `__HOME__` in the copied QML with your home path, copy the executable `dotfiles/local/bin/niri-gcal` to `~/.local/bin/`, enable the plugin, and add `googleCalendar` to the bar.

The widget uses gcalcli's existing Google credentials; it never asks for or stores them. Agenda data is cached privately in `${XDG_CACHE_HOME:-~/.cache}/niri-gcal/`. By default gcalcli's calendars are used. To select specific calendars, create `~/.config/niri-gcal/config.json` containing `{"calendars": ["Work", "Family"]}` with exact gcalcli calendar names. If sign-in or sync fails, run `gcalcli agenda --tsv` in a terminal to diagnose it. This is an independent DMS implementation inspired by [Google Calendar for Omarchy](https://github.com/hussainanjar/omarchy-gcal); it does not provide the upstream full-screen reminder or in-panel OAuth setup. No live Google account or desktop session is needed to run the repository tests.
