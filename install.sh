#!/usr/bin/env bash
# install.sh — rebuild this Niri + Hyprland + Dux Shell (DMS) desktop on a fresh Arch Linux install.
#
# Usage:
#   ./install.sh [options]
#     --no-aur           skip AUR packages (and yay bootstrap)
#     --no-system        skip /etc changes (greetd, zram) and service enabling
#     --with-hardware    also install machine-specific pkgs (kernel, ucode, firmware, fs tools)
#     --passwordless-pacman  create /etc/sudoers.d/pacman-nopasswd (matches original machine)
#     --dry-run          print what would happen, change nothing
#     -y, --yes          don't ask for confirmation
#   Env:
#     TAVILY_API_KEY=tvly-...   inject your Tavily key (shell rc + OpenCode MCP). Optional.
#
# Existing files are backed up to ~/.config-backup-<timestamp>/ before being overwritten.
set -euo pipefail

BUNDLE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOT="$BUNDLE/dotfiles"
PKG="$BUNDLE/packages"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.config-backup-$STAMP"

DO_AUR=1; DO_SYSTEM=1; DO_HW=0; DO_PACMAN_NOPASS=0; DRY=0; ASSUME_YES=0
for a in "$@"; do
    case "$a" in
        --no-aur) DO_AUR=0 ;;
        --no-system) DO_SYSTEM=0 ;;
        --with-hardware) DO_HW=1 ;;
        --passwordless-pacman) DO_PACMAN_NOPASS=1 ;;
        --dry-run) DRY=1 ;;
        -y|--yes) ASSUME_YES=1 ;;
        -h|--help) sed -n '2,19p' "${BASH_SOURCE[0]}"; exit 0 ;;
        *) echo "Unknown option: $a" >&2; exit 2 ;;
    esac
done

# Machine-specific packages: skipped unless --with-hardware (a new box has its own).
HW_PKGS=(linux linux-headers linux-firmware linux-firmware-qcom intel-ucode efibootmgr
         mkinitcpio xfsprogs libva-intel-driver reflector zram-generator base base-devel)

say()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m  %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m  %s\n' "$*" >&2; exit 1; }
run()  { if [ "$DRY" = 1 ]; then printf '   [dry-run] %s\n' "$*"; else "$@"; fi; }

# ── Preflight ─────────────────────────────────────────────────────────────────
[ "$(id -u)" -ne 0 ] || die "Run as your normal user (sudo is used when needed), not root."
[ -f /etc/arch-release ] || die "This installer targets Arch Linux."
[ -d "$DOT" ] || die "dotfiles/ not found next to install.sh."
command -v sudo >/dev/null || die "sudo is required."

say "Bundle: $BUNDLE"
say "Target user: $USER  ($HOME)"
if [ "$ASSUME_YES" != 1 ] && [ "$DRY" != 1 ]; then
    read -rp "Install Niri + Hyprland + Dux Shell setup now? Existing configs are backed up. [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]] || exit 0
fi
[ "$DRY" = 1 ] || sudo -v

# ── 1. Packages ───────────────────────────────────────────────────────────────
say "Installing native packages"
mapfile -t NATIVE < <(grep -vE '^\s*(#|$)' "$PKG/pacman.txt")
if [ "$DO_HW" != 1 ]; then
    FILTERED=()
    for p in "${NATIVE[@]}"; do
        skip=0; for h in "${HW_PKGS[@]}"; do [ "$p" = "$h" ] && skip=1 && break; done
        [ "$skip" = 1 ] || FILTERED+=("$p")
    done
    NATIVE=("${FILTERED[@]}")
    # base/base-devel are still needed for AUR builds
    NATIVE+=(base-devel git)
fi
run sudo pacman -Syu --needed --noconfirm "${NATIVE[@]}" uv

if [ "$DO_AUR" = 1 ]; then
    if ! command -v yay >/dev/null; then
        say "Bootstrapping yay"
        if [ "$DRY" = 1 ]; then echo "   [dry-run] build yay-bin from AUR"; else
            tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
            git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
            (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
        fi
    fi
    say "Installing AUR packages"
    mapfile -t AUR < <(grep -vE '^\s*(#|$)|-debug$|^yay' "$PKG/aur.txt")
    [ "${#AUR[@]}" -gt 0 ] && run yay -S --needed --noconfirm "${AUR[@]}"
fi

# ── 2. Dotfiles ───────────────────────────────────────────────────────────────
# Copy src → dst, replacing __HOME__, backing up whatever was there.
install_file() {
    local src="$1" dst="$2" mode="${3:-}"
    [ "$DRY" = 1 ] && { printf '   [dry-run] %s\n' "$dst"; return; }
    if [ -e "$dst" ] && ! cmp -s <(sed "s#__HOME__#$HOME#g" "$src") "$dst"; then
        mkdir -p "$BACKUP/$(dirname "${dst#$HOME/}")"
        cp -a "$dst" "$BACKUP/${dst#$HOME/}"
    fi
    mkdir -p "$(dirname "$dst")"
    sed "s#__HOME__#$HOME#g" "$src" > "$dst"
    [ -n "$mode" ] && chmod "$mode" "$dst"
    return 0
}
install_tree() {   # install_tree <srcdir> <dstdir>
    local s="$1" d="$2" f rel
    [ -d "$s" ] || return 0
    while IFS= read -r -d '' f; do
        rel="${f#$s/}"
        if [ -x "$f" ]; then install_file "$f" "$d/$rel" 755; else install_file "$f" "$d/$rel"; fi
    done < <(find "$s" -type f -print0)
}

say "Installing dotfiles → ~/.config"
install_tree "$DOT/config" "$HOME/.config"

say "Installing scripts → ~/.local/bin"
install_tree "$DOT/local/bin" "$HOME/.local/bin"
install_tree "$DOT/local/share" "$HOME/.local/share"

say "Installing shell rc files"
for f in .bashrc .bash_profile .profile .zshrc; do
    [ -f "$DOT/shell/$f" ] && install_file "$DOT/shell/$f" "$HOME/$f"
done

# Zsh plugins (fzf-tab, zsh-autopair, zsh-you-should-use)
if [ "$DRY" != 1 ]; then
    say "Setting up Zsh plugins"
    mkdir -p "$HOME/.zsh/plugins"
    [ -d "$HOME/.zsh/plugins/fzf-tab" ] || git clone --depth 1 https://github.com/Aloxaf/fzf-tab "$HOME/.zsh/plugins/fzf-tab" 2>/dev/null || true
    [ -d "$HOME/.zsh/plugins/zsh-autopair" ] || git clone --depth 1 https://github.com/hlissner/zsh-autopair "$HOME/.zsh/plugins/zsh-autopair" 2>/dev/null || true
    [ -d "$HOME/.zsh/plugins/zsh-you-should-use" ] || git clone --depth 1 https://github.com/MichaelAquilina/zsh-you-should-use "$HOME/.zsh/plugins/zsh-you-should-use" 2>/dev/null || true
fi

[ -f "$DOT/AGENTS.md" ] && install_file "$DOT/AGENTS.md" "$HOME/AGENTS.md"
[ -f "$DOT/codex/config.toml" ] && install_file "$DOT/codex/config.toml" "$HOME/.codex/config.toml" 600

say "Installing systemd user units"
install_tree "$DOT/systemd-user" "$HOME/.config/systemd/user"

# ── 3. Secrets: Tavily ────────────────────────────────────────────────────────
if [ "$DRY" != 1 ]; then
    OC="$HOME/.config/opencode/opencode.json"
    RCS=("$HOME/.bashrc" "$HOME/.profile" "$HOME/.zshrc")
    if [ -n "${TAVILY_API_KEY:-}" ]; then
        say "Injecting Tavily API key"
        for f in "${RCS[@]}" "$OC"; do
            [ -f "$f" ] && sed -i "s#__TAVILY_API_KEY__#$TAVILY_API_KEY#g" "$f"
        done
        # Antigravity MCP
        mkdir -p "$HOME/.gemini/config"
        cat > "$HOME/.gemini/config/mcp_config.json" <<EOF
{
  "mcpServers": {
    "tavily": {
      "command": "npx",
      "args": ["-y", "tavily-mcp"],
      "env": { "TAVILY_API_KEY": "$TAVILY_API_KEY" }
    }
  }
}
EOF
        chmod 600 "$HOME/.gemini/config/mcp_config.json" "$OC" 2>/dev/null || true
    else
        warn "TAVILY_API_KEY not set — removing Tavily placeholders (re-run with TAVILY_API_KEY=tvly-... to add)."
        for f in "${RCS[@]}"; do
            [ -f "$f" ] && sed -i -e '/__TAVILY_API_KEY__/d' -e '/^# Tavily API Key$/d' "$f"
        done
        [ -f "$OC" ] && command -v jq >/dev/null && \
            jq 'del(.mcp)' "$OC" > "$OC.tmp" && mv "$OC.tmp" "$OC"
    fi

    # Experiential Labs API Key (GLM-5.3)
    EXP_KEY="${EXPERIENTIALLABS_API_KEY:-${EXPLABS_API_KEY:-}}"
    ENV_CONF="$HOME/.config/environment.d/95-experientiallabs.conf"
    if [ -n "$EXP_KEY" ]; then
        say "Injecting Experiential Labs API key"
        for f in "${RCS[@]}" "$OC" "$ENV_CONF"; do
            [ -f "$f" ] && sed -i "s#__EXPERIENTIALLABS_API_KEY__#$EXP_KEY#g" "$f"
        done
    else
        warn "EXPERIENTIALLABS_API_KEY not set — removing Experiential Labs placeholders."
        for f in "${RCS[@]}"; do
            [ -f "$f" ] && sed -i -e '/__EXPERIENTIALLABS_API_KEY__/d' -e '/^# Experiential Labs API Key$/d' "$f"
        done
        [ -f "$ENV_CONF" ] && rm -f "$ENV_CONF"
        [ -f "$OC" ] && command -v jq >/dev/null && \
            jq 'del(.providers.experientiallabs)' "$OC" > "$OC.tmp" && mv "$OC.tmp" "$OC"
    fi
fi

# ── 4. System config + services ───────────────────────────────────────────────
if [ "$DO_SYSTEM" = 1 ]; then
    say "Installing greetd (DMS greeter) config"
    if [ -f "$DOT/etc/greetd/config.toml" ]; then
        run sudo install -d -m 755 /etc/greetd/niri
        [ -f /etc/greetd/config.toml ] && run sudo cp -a /etc/greetd/config.toml "/etc/greetd/config.toml.backup-$STAMP"
        run sudo install -m 644 "$DOT/etc/greetd/config.toml" /etc/greetd/config.toml
        for k in "$DOT"/etc/greetd/niri/*.kdl; do
            [ -f "$k" ] && run sudo install -m 644 "$k" "/etc/greetd/niri/$(basename "$k")"
        done
    fi
    if [ "$DO_HW" = 1 ] && [ -f "$DOT/etc/zram-generator.conf" ]; then
        run sudo install -m 644 "$DOT/etc/zram-generator.conf" /etc/systemd/zram-generator.conf
    fi
    if [ -f "$DOT/etc/udev/rules.d/72-uinput-uaccess.rules" ]; then
        say "udev: uaccess ACL for /dev/uinput (ydotoold)"
        run sudo install -D -m 644 "$DOT/etc/udev/rules.d/72-uinput-uaccess.rules" \
            /etc/udev/rules.d/72-uinput-uaccess.rules
        run sudo udevadm control --reload-rules
        run sudo udevadm trigger --subsystem-match=misc --sysname-match=uinput --action=change
    fi

    say "Groups (docker, video, render)"
    for g in docker video render; do
        getent group "$g" >/dev/null && run sudo usermod -aG "$g" "$USER"
    done

    if [ "$DO_PACMAN_NOPASS" = 1 ]; then
        say "Passwordless pacman"
        if [ "$DRY" = 1 ]; then echo "   [dry-run] /etc/sudoers.d/pacman-nopasswd"; else
            echo "$USER ALL=(root) NOPASSWD: /usr/bin/pacman" | sudo tee /etc/sudoers.d/pacman-nopasswd >/dev/null
            sudo chmod 440 /etc/sudoers.d/pacman-nopasswd
            sudo visudo -cf /etc/sudoers.d/pacman-nopasswd >/dev/null || { sudo rm -f /etc/sudoers.d/pacman-nopasswd; die "sudoers validation failed"; }
        fi
    fi

    say "Enabling system services"
    for s in NetworkManager bluetooth docker power-profiles-daemon rtkit-daemon; do
        systemctl list-unit-files "$s.service" >/dev/null 2>&1 && run sudo systemctl enable "$s.service"
    done
    # greetd is the display manager (DMS greeter on tty1)
    run sudo systemctl enable greetd.service
fi

# ── 5. User services & wiring ─────────────────────────────────────────────────
say "Wiring user services (DMS + Nautilus bridge + ydotoold)"
if [ "$DRY" != 1 ]; then
    mkdir -p "$HOME/.config/systemd/user/niri.service.wants" \
             "$HOME/.config/systemd/user/hyprland-session.target.wants" \
             "$HOME/.config/systemd/user/default.target.wants"
    ln -sfn /usr/lib/systemd/user/dms.service "$HOME/.config/systemd/user/niri.service.wants/dms.service"
    ln -sfn /usr/lib/systemd/user/dms.service "$HOME/.config/systemd/user/hyprland-session.target.wants/dms.service"
    if [ -f "$HOME/.config/systemd/user/nautilus-clipboard-bridge.service" ]; then
        for w in niri.service.wants hyprland-session.target.wants default.target.wants; do
            ln -sfn "$HOME/.config/systemd/user/nautilus-clipboard-bridge.service" \
                    "$HOME/.config/systemd/user/$w/nautilus-clipboard-bridge.service"
        done
    fi
    if [ -f "$HOME/.config/systemd/user/ydotoold.service" ]; then
        ln -sfn "$HOME/.config/systemd/user/ydotoold.service" \
                "$HOME/.config/systemd/user/niri.service.wants/ydotoold.service"
    fi
    systemctl --user daemon-reload 2>/dev/null || true

    # Make sure our scripts are executable and Nautilus picks up the python extensions
    chmod +x "$HOME"/.local/bin/* 2>/dev/null || true
    command -v update-desktop-database >/dev/null && update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    command -v xdg-user-dirs-update >/dev/null && xdg-user-dirs-update 2>/dev/null || true
    command -v fc-cache >/dev/null && fc-cache -f >/dev/null 2>&1 || true
fi

# ── 6. External CLIs (OpenCode, Qoder & Boat) ─────────────────────────────────
if ! command -v opencode >/dev/null; then
    say "OpenCode not found in repos — skipping (install later: https://opencode.ai)"
fi
if ! command -v qodercli >/dev/null; then
    say "Installing Qoder CLI"
    if [ "$DRY" = 1 ]; then
        echo "   [dry-run] curl -fsSL https://qoder.com/install | bash"
    else
        curl -fsSL https://qoder.com/install | bash || warn "Qoder CLI installation failed"
        ln -sfn "$HOME/.local/bin/qodercli" "$HOME/.local/bin/qoder" 2>/dev/null || true
    fi
fi
if ! command -v boat >/dev/null; then
    say "Installing Boat CLI"
    if [ "$DRY" = 1 ]; then
        echo "   [dry-run] curl -fsSL https://boat.dev/install | sh"
    else
        curl -fsSL https://boat.dev/install | sh || warn "Boat CLI installation failed"
    fi
fi

# ── 7. Validate ───────────────────────────────────────────────────────────────
if [ "$DRY" != 1 ] && command -v niri >/dev/null; then
    say "Validating Niri config"
    niri validate --config "$HOME/.config/niri/config.kdl" || warn "niri config reported problems"
fi
if [ "$DRY" != 1 ] && command -v Hyprland >/dev/null && [ -f "$HOME/.config/hypr/hyprland.lua" ]; then
    say "Validating Hyprland config"
    Hyprland -c "$HOME/.config/hypr/hyprland.lua" --verify-config || warn "Hyprland config reported problems"
fi

cat <<EOF

$(printf '\033[1;32m✔ Done.\033[0m')
  • Backups of replaced files: $BACKUP (only created if something differed)
  • Reboot (or log out), and greetd's DMS greeter will let you choose Niri or Hyprland.
  • Not included on purpose (set up manually): logins for Brave/gh/Codex/OpenCode, the WeChat AppImage
    (~/.local/share/appimages/WeChatLinux_x86_64.AppImage), Obsidian vault, wallpapers.
  • Keybindings overlay: Super+Shift+/  ·  full reference: Obsidian Vault/keybindings.md
EOF
