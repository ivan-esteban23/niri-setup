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
