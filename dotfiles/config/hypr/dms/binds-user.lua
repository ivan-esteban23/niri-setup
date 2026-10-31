-- Optional per-user keybind overrides (managed by DMS). Loaded after default binds.

-- === Sudo Timer (600 min passwordless sudo) ===
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("__HOME__/.local/bin/sudo-timer start"))
hl.bind("SUPER + ALT + S", hl.dsp.exec_cmd("__HOME__/.local/bin/sudo-timer stop"))

-- === Do Not Disturb (DMS Notifications) ===
hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd("__HOME__/.local/bin/toggle-dnd"))

-- === BitTorrent ===
hl.bind("SUPER + ALT + T", hl.dsp.exec_cmd("rqbit-desktop"))

-- === Drag & Drop Clipboard Shelf ===
hl.bind("SUPER + B", hl.dsp.exec_cmd("__HOME__/.local/bin/toggle-drag-shelf"))

-- === App Launchers ===
hl.bind("SUPER + S", hl.dsp.exec_cmd("localsend"))
hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("vlc"))
hl.bind("SUPER + ALT + W", hl.dsp.exec_cmd("__HOME__/.local/share/appimages/WeChatLinux_x86_64.AppImage"))

-- === WebApp Manager ===
hl.bind("SUPER + G", hl.dsp.exec_cmd("dms ipc call control-center openWith plugin_webappManager"))

-- === Video Downloader ===
hl.bind("SUPER + ALT + V", hl.dsp.exec_cmd("dms ipc call control-center openWith plugin_videoDownloader"))

-- === Image Prompt Builder ===
hl.bind("SUPER + SHIFT + B", hl.dsp.exec_cmd("__HOME__/.local/bin/img-prompt stage"))
hl.bind("SUPER + SHIFT + G", hl.dsp.exec_cmd("__HOME__/.local/bin/img-prompt run"))
