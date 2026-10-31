"""Offline checks for the curated DMS theme files."""
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "dotfiles/config/dms/plugins/themeSwitcher"


def luminance(color):
    channels = [int(color[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    linear = [v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in channels]
    return sum(a * b for a, b in zip(linear, (0.2126, 0.7152, 0.0722)))


def contrast(first, second):
    low, high = sorted((luminance(first), luminance(second)))
    return (high + 0.05) / (low + 0.05)


class ThemePaletteTests(unittest.TestCase):
    def test_every_picker_choice_has_a_valid_palette(self):
        qml = (ROOT / "ThemeSwitcher.qml").read_text()
        choices = re.findall(r'\{ id: "([a-z-]+)", name:', qml)
        self.assertEqual(len(choices), 8)
        self.assertEqual(len(set(choices)), len(choices))
        self.assertEqual(set(choices), {p.stem for p in (ROOT / "themes").glob("*.json")})
        for choice in choices:
            with self.subTest(choice=choice):
                palette = json.loads((ROOT / "themes" / (choice + ".json")).read_text())
                for key in ("surface", "surfaceText", "surfaceVariant", "surfaceVariantText", "primary", "primaryText", "background", "backgroundText"):
                    self.assertRegex(palette[key], r"^#[0-9a-fA-F]{6}$")
                for foreground, background in (("surfaceText", "surface"), ("surfaceVariantText", "surfaceVariant"), ("primaryText", "primary"), ("backgroundText", "background")):
                    self.assertGreaterEqual(contrast(palette[foreground], palette[background]), 4.5, (choice, foreground, background))

    def test_light_palettes_use_warm_surfaces(self):
        for choice in ("gruvbox-light", "solarized-light", "rose-pine-dawn"):
            palette = json.loads((ROOT / "themes" / (choice + ".json")).read_text())
            with self.subTest(choice=choice):
                color = palette["surface"].lower()
                self.assertNotEqual(color, "#ffffff")
                self.assertGreaterEqual(int(color[1:3], 16), int(color[5:7], 16))


if __name__ == "__main__":
    unittest.main()
