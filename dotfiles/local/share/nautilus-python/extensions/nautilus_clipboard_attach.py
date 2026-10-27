"""
Nautilus Clipboard Attach Extension (Nautilus 4.1)
Makes attaching files and images from Nautilus into Antigravity CLI, OpenCode,
and browsers effortless via right-click context menu actions.
"""

import os
import subprocess
from pathlib import Path
from typing import List

import gi
try:
    gi.require_version("Nautilus", "4.1")
except ValueError:
    gi.require_version("Nautilus", "4.0")
from gi.repository import GObject, Nautilus

HELPER_BIN = str(Path.home() / ".local" / "bin" / "clip-attach-helper")
IMAGE_EXTS = {
    ".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp", ".svg", ".tiff", ".tif", ".ico", ".avif"
}


def _extract_paths(files: List[Nautilus.FileInfo]) -> List[str]:
    paths: List[str] = []
    for f in files:
        try:
            loc = f.get_location()
            if loc is not None:
                p = loc.get_path()
                if p:
                    paths.append(p)
        except Exception:
            pass
    return paths


class NautilusClipboardAttachProvider(GObject.GObject, Nautilus.MenuProvider):
    def _run_helper(self, _menu_item: Nautilus.MenuItem, cmd: str, paths: List[str]) -> None:
        try:
            subprocess.Popen([HELPER_BIN, cmd, *paths])
        except Exception:
            pass

    def _open_drag_shelf(self, _menu_item: Nautilus.MenuItem, paths: List[str]) -> None:
        try:
            subprocess.Popen(["__HOME__/.local/bin/clipboard-drag-shelf", *paths])
        except Exception:
            pass

    def get_file_items(self, files: List[Nautilus.FileInfo]) -> List[Nautilus.MenuItem]:
        paths = _extract_paths(files)
        if not paths:
            return []

        has_image = len(paths) == 1 and Path(paths[0]).suffix.lower() in IMAGE_EXTS
        has_file = any(os.path.isfile(p) for p in paths)

        # 1. Top-level fast action: "📎 Copy to Attach Here"
        smart_label = (
            "📎 Copy Image to Attach Here"
            if has_image
            else "📎 Copy Path to Attach Here"
        )
        smart_item = Nautilus.MenuItem(
            name="ClipboardAttach::SmartCopy",
            label=smart_label,
            tip="Copy image pixels (for images) or clean path (for files) ready to paste in Antigravity CLI / browser",
        )
        smart_item.connect("activate", self._run_helper, "smart", paths)

        # 2. Submenu with specialized clipboard attach options
        submenu = Nautilus.Menu()

        if has_image:
            img_item = Nautilus.MenuItem(
                name="ClipboardAttach::CopyImagePixels",
                label="🖼️ Copy Image Pixels (PNG/JPEG)",
                tip="Copy raw image pixel data to Wayland clipboard",
            )
            img_item.connect("activate", self._run_helper, "image", paths)
            submenu.append_item(img_item)

        path_item = Nautilus.MenuItem(
            name="ClipboardAttach::CopyCleanPath",
            label="📍 Copy Clean File Path (/home/...)",
            tip="Copy absolute file path(s) as plain text",
        )
        path_item.connect("activate", self._run_helper, "path", paths)
        submenu.append_item(path_item)

        at_item = Nautilus.MenuItem(
            name="ClipboardAttach::CopyAtPath",
            label="🤖 Copy as @path (AI Prompt Reference)",
            tip="Copy file path prefixed with @ for AI CLI tools",
        )
        at_item.connect("activate", self._run_helper, "at-path", paths)
        submenu.append_item(at_item)

        if has_file:
            content_item = Nautilus.MenuItem(
                name="ClipboardAttach::CopyContent",
                label="📄 Copy File Text Content",
                tip="Copy the text contents of the selected file(s) to clipboard",
            )
            content_item.connect("activate", self._run_helper, "content", paths)
            submenu.append_item(content_item)

        target_folder = paths[0] if os.path.isdir(paths[0]) else os.path.dirname(paths[0])
        paste_file_item = Nautilus.MenuItem(
            name="ClipboardAttach::PasteClipboardAsFile",
            label="💾 Save Active Clipboard Here as File",
            tip="Save current clipboard image or text as a new file in this folder",
        )
        paste_file_item.connect("activate", self._run_helper, "paste-into", [target_folder])
        submenu.append_item(paste_file_item)

        options_menu_item = Nautilus.MenuItem(
            name="ClipboardAttach::OptionsMenu",
            label="📋 Clipboard Attach Options",
            tip="More options to copy or save clipboard attachments",
        )
        options_menu_item.set_submenu(submenu)

        shelf_item = Nautilus.MenuItem(
            name="ClipboardAttach::OpenDragShelf",
            label="🧲 Pin to Floating Drag Shelf (Mod+B)",
            tip="Open floating Drag & Drop shelf over Alacritty to drag files into agy or opencode",
        )
        shelf_item.connect("activate", self._open_drag_shelf, paths)

        return [smart_item, shelf_item, options_menu_item]

    def get_background_items(self, current_folder: Nautilus.FileInfo) -> List[Nautilus.MenuItem]:
        paths = _extract_paths([current_folder])
        if not paths:
            return []
        folder = paths[0]

        paste_item = Nautilus.MenuItem(
            name="ClipboardAttach::BgPasteClipboardAsFile",
            label="💾 Save Active Clipboard Here as File",
            tip="Save current clipboard image or text as a file in this folder",
        )
        paste_item.connect("activate", self._run_helper, "paste-into", [folder])
        return [paste_item]
