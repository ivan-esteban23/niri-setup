"""
Nautilus Clipboard History Extension (Nautilus 4.1)
Provides a live "🕒 Clipboard History" submenu inside Nautilus to browse recent
clipboard entries (images & text), restore any entry to the active clipboard,
save any history entry directly into the current folder as a file, or open the
full Clipboard History UI.
"""

import json
import os
import subprocess
from pathlib import Path
from typing import Any, Dict, List

import gi
try:
    gi.require_version("Nautilus", "4.1")
except ValueError:
    gi.require_version("Nautilus", "4.0")
from gi.repository import GObject, Nautilus

HELPER_BIN = str(Path.home() / ".local" / "bin" / "clip-attach-helper")


def _fetch_history(limit: int = 12) -> List[Dict[str, Any]]:
    try:
        out = subprocess.check_output(
            ["dms", "clipboard", "history", "--json"],
            text=True,
            timeout=1.5,
            stderr=subprocess.DEVNULL,
        )
        items = json.loads(out)
        if isinstance(items, list):
            return items[:limit]
    except Exception:
        pass
    return []


def _format_entry_label(entry: Dict[str, Any]) -> str:
    eid = entry.get("id", "?")
    is_img = bool(entry.get("isImage"))
    preview = " ".join(str(entry.get("preview", "")).splitlines()).strip()
    if len(preview) > 48:
        preview = preview[:45] + "..."
    icon = "🖼️" if is_img else "📝"
    pin = "📌 " if entry.get("pinned") else ""
    return f"{pin}{icon} #{eid}: {preview}"


class NautilusClipboardHistoryProvider(GObject.GObject, Nautilus.MenuProvider):
    def _restore_entry(self, _item: Nautilus.MenuItem, entry_id: int, preview: str) -> None:
        try:
            subprocess.Popen(["dms", "clipboard", "get", str(entry_id), "--copy"])
            subprocess.Popen(
                [
                    "notify-send",
                    "-a",
                    "Clipboard History",
                    "-i",
                    "edit-paste",
                    f"🕒 Restored Clipboard #{entry_id}",
                    preview,
                ]
            )
        except Exception:
            pass

    def _save_entry_here(self, _item: Nautilus.MenuItem, folder: str, entry_id: int) -> None:
        try:
            subprocess.Popen([HELPER_BIN, "paste-into", folder, str(entry_id)])
        except Exception:
            pass

    def _open_history_modal(self, _item: Nautilus.MenuItem) -> None:
        try:
            subprocess.Popen(["dms", "ipc", "call", "clipboard", "toggle"])
        except Exception:
            pass

    def _clear_history(self, _item: Nautilus.MenuItem) -> None:
        try:
            subprocess.Popen(["dms", "clipboard", "clear"])
            subprocess.Popen(
                [
                    "notify-send",
                    "-a",
                    "Clipboard History",
                    "-i",
                    "user-trash",
                    "🗑️ Clipboard History Cleared",
                    "All unpinned clipboard history entries were cleared.",
                ]
            )
        except Exception:
            pass

    def _build_history_menu(self, target_folder: str, prefix: str) -> Nautilus.MenuItem:
        root_item = Nautilus.MenuItem(
            name=f"ClipboardHistory::{prefix}Root",
            label="🕒 Clipboard History",
            tip="Browse, restore, or save recent clipboard history items",
        )
        submenu = Nautilus.Menu()
        root_item.set_submenu(submenu)

        open_ui = Nautilus.MenuItem(
            name=f"ClipboardHistory::{prefix}OpenUI",
            label="🔍 Open Visual Clipboard History (Mod+V)",
            tip="Open the full DankMaterialShell Clipboard History modal",
        )
        open_ui.connect("activate", self._open_history_modal)
        submenu.append_item(open_ui)

        entries = _fetch_history(limit=12)
        if entries:
            save_submenu_parent = Nautilus.MenuItem(
                name=f"ClipboardHistory::{prefix}SaveSubmenu",
                label="💾 Save History Item Here as File",
                tip="Save any clipboard history item directly into this folder",
            )
            save_submenu = Nautilus.Menu()
            save_submenu_parent.set_submenu(save_submenu)
            submenu.append_item(save_submenu_parent)

            for entry in entries:
                eid = int(entry.get("id", 0))
                label = _format_entry_label(entry)
                preview = str(entry.get("preview", ""))

                restore_item = Nautilus.MenuItem(
                    name=f"ClipboardHistory::{prefix}Restore_{eid}",
                    label=label,
                    tip=f"Click to copy item #{eid} back to active clipboard",
                )
                restore_item.connect("activate", self._restore_entry, eid, preview)
                submenu.append_item(restore_item)

                save_item = Nautilus.MenuItem(
                    name=f"ClipboardHistory::{prefix}Save_{eid}",
                    label=f"💾 Save {label}",
                    tip=f"Save clipboard item #{eid} as a file in {os.path.basename(target_folder) or target_folder}",
                )
                save_item.connect("activate", self._save_entry_here, target_folder, eid)
                save_submenu.append_item(save_item)

            clear_item = Nautilus.MenuItem(
                name=f"ClipboardHistory::{prefix}Clear",
                label="🗑️ Clear Clipboard History",
                tip="Clear unpinned clipboard history items",
            )
            clear_item.connect("activate", self._clear_history)
            submenu.append_item(clear_item)
        else:
            empty_item = Nautilus.MenuItem(
                name=f"ClipboardHistory::{prefix}Empty",
                label="(Clipboard history is empty)",
                sensitive=False,
            )
            submenu.append_item(empty_item)

        return root_item

    def get_file_items(self, files: List[Nautilus.FileInfo]) -> List[Nautilus.MenuItem]:
        if not files:
            return []
        loc = files[0].get_location()
        p = loc.get_path() if loc else None
        if not p:
            return []
        folder = p if os.path.isdir(p) else os.path.dirname(p)
        return [self._build_history_menu(folder, prefix="File")]

    def get_background_items(self, current_folder: Nautilus.FileInfo) -> List[Nautilus.MenuItem]:
        loc = current_folder.get_location()
        folder = loc.get_path() if loc else str(Path.home())
        return [self._build_history_menu(folder, prefix="Bg")]
