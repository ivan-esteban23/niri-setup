#!/usr/bin/env bash
# sync-from-system.sh — snapshot the LIVE machine into this bundle (dotfiles/ + packages/).
# Secrets are stripped and $HOME is replaced by the __HOME__ token, so the bundle is portable.
# Re-run any time you change your setup, then commit/copy the folder.
set -euo pipefail

BUNDLE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOT="$BUNDLE/dotfiles"
PKG="$BUNDLE/packages"
RSYNC=(rsync -a --delete --exclude='__pycache__' --exclude='*.pyc' --exclude='.git')

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }

mkdir -p "$DOT" "$PKG"

# ── Packages ──────────────────────────────────────────────────────────────────
say "Package lists"
pacman -Qqen | sort > "$PKG/pacman.txt"   # explicit, native repo
pacman -Qqem | sort > "$PKG/aur.txt"      # explicit, foreign (AUR)

# Explicitly ensure required runtime packages for custom scripts & Hyprland are included
REQUIRED_PKGS=(python python-gobject gtk4 imagemagick libnotify upower zstd curl tar hyprland xdg-desktop-portal-hyprland)
for p in "${REQUIRED_PKGS[@]}"; do
    pacman -Q "$p" >/dev/null 2>&1 && echo "$p" >> "$PKG/pacman.txt"
done
sort -u "$PKG/pacman.txt" -o "$PKG/pacman.txt"

# ── ~/.config directories ─────────────────────────────────────────────────────
CONFIG_DIRS=(alacritty foot btop cava fontconfig gtk-3.0 gtk-4.0 mpv niri hypr yazi fish
             environment.d desktop nautilus)
say "~/.config dirs"
for d in "${CONFIG_DIRS[@]}"; do
    [ -d "$HOME/.config/$d" ] || continue
    mkdir -p "$DOT/config/$d"
    "${RSYNC[@]}" "$HOME/.config/$d/" "$DOT/config/$d/"
done

# Dux Shell: settings + plugins (skip changelog/first-launch markers)
say "Dux Shell (dms)"
mkdir -p "$DOT/config/dms"
"${RSYNC[@]}" --exclude='.changelog-*' --exclude='.firstlaunch' \
    "$HOME/.config/dms/" "$DOT/config/dms/"

# Loose files in ~/.config
for f in xdg-terminals.list mimeapps.list brave-origin-flags.conf QtProject.conf user-dirs.dirs; do
    [ -f "$HOME/.config/$f" ] && cp -f "$HOME/.config/$f" "$DOT/config/$f"
done

# systemd user units (real files only; symlink wants/ are recreated by the installer)
say "systemd user units"
mkdir -p "$DOT/systemd-user"
find "$HOME/.config/systemd/user" -maxdepth 1 -type f -name '*.service' -exec cp -f {} "$DOT/systemd-user/" \;

# OpenCode (config sanitized below), AGENTS, skills
say "OpenCode"
mkdir -p "$DOT/config/opencode"
"${RSYNC[@]}" --exclude='node_modules' --exclude='bun.lock' --exclude='package-lock.json' \
    --exclude='service*.json' --exclude='auth.json' --exclude='*.db*' --delete-excluded \
    "$HOME/.config/opencode/" "$DOT/config/opencode/"

# Codex config (no auth.json!) and global agent rules
say "Codex + AGENTS.md"
mkdir -p "$DOT/codex"
[ -f "$HOME/.codex/config.toml" ] && cp -f "$HOME/.codex/config.toml" "$DOT/codex/config.toml"
[ -f "$HOME/AGENTS.md" ] && cp -f "$HOME/AGENTS.md" "$DOT/AGENTS.md"

# ~/.local
say "~/.local (bin, nautilus-python, desktop entries)"
mkdir -p "$DOT/local/bin" "$DOT/local/share/nautilus-python/extensions" "$DOT/local/share/applications"
find "$HOME/.local/bin" -maxdepth 1 -type f -executable \
     ! -name uv ! -name uvx ! -name httpx ! -name opencode -exec cp -f {} "$DOT/local/bin/" \;
"${RSYNC[@]}" "$HOME/.local/share/nautilus-python/extensions/" "$DOT/local/share/nautilus-python/extensions/"
for f in "$HOME"/.local/share/applications/*.desktop; do
    [ -f "$f" ] && cp -f "$f" "$DOT/local/share/applications/"
done

# Shell rc files
say "Shell rc files"
mkdir -p "$DOT/shell"
for f in .bashrc .bash_profile .profile .zshrc; do
    [ -f "$HOME/$f" ] && cp -f "$HOME/$f" "$DOT/shell/$f"
done

# System files that need root to install (readable ones only)
say "System files (greetd, zram)"
mkdir -p "$DOT/etc/greetd/niri"
cp -f /etc/greetd/config.toml "$DOT/etc/greetd/config.toml" 2>/dev/null || true
cp -f /etc/greetd/niri/*.kdl "$DOT/etc/greetd/niri/" 2>/dev/null || true
if [ -r /etc/systemd/zram-generator.conf ]; then
    cp -f /etc/systemd/zram-generator.conf "$DOT/etc/zram-generator.conf"
fi

# ── Sanitize ──────────────────────────────────────────────────────────────────
say "Sanitizing (secrets → placeholders, \$HOME → __HOME__)"
# Strip Tavily keys and any obvious API tokens.
mapfile -t TEXT_FILES < <(grep -rIl . "$DOT" 2>/dev/null || true)
for f in "${TEXT_FILES[@]}"; do
    sed -i -E \
        -e "s#tvly-[A-Za-z0-9_-]+#__TAVILY_API_KEY__#g" \
        -e "s#xpl_[A-Za-z0-9_]+#__EXPERIENTIALLABS_API_KEY__#g" \
        -e "s#box__[A-Za-z0-9_-]+#__BOAT_TOKEN__#g" \
        -e "s#(sk|ghp|gho|github_pat)[-_][A-Za-z0-9_]{20,}#__REDACTED_TOKEN__#g" \
        -e "s#$HOME#__HOME__#g" \
        "$f"
done

# Never ship credential stores
rm -f "$DOT/codex/auth.json" "$DOT/config/opencode/auth.json" 2>/dev/null || true

# Safety net: abort if anything that looks like a live credential survived.
if grep -rIE '"(password|api_?key|secret|token|access_token|refresh_token)"[[:space:]]*:[[:space:]]*"[^_"][^"]{7,}"' "$DOT" \
        | grep -v '__' ; then
    echo "!! Possible secret left in bundle (see above). Fix the sync script before sharing." >&2
    exit 1
fi

echo
say "Done. Bundle: $BUNDLE"
echo "   packages: $(wc -l < "$PKG/pacman.txt") native + $(wc -l < "$PKG/aur.txt") AUR"
echo "   files:    $(find "$DOT" -type f | wc -l) in dotfiles/"
echo "   Scan for leftovers: grep -rniE 'tvly-|api[_-]?key|token|secret|password' \"$DOT\""
