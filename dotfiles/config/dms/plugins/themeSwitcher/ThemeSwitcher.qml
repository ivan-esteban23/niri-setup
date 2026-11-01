import QtQuick
import Quickshell
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root
    property string pluginId: "themeSwitcher"
    property var pluginService: null
    property var popoutService: null
    readonly property string configDirectory: {
        const xdg = Quickshell.env("XDG_CONFIG_HOME");
        return xdg && xdg.charAt(0) === "/" ? xdg : Quickshell.env("HOME") + "/.config";
    }
    readonly property string themeDirectory: configDirectory + "/dms/plugins/themeSwitcher/themes/"
    property string notice: ""
    property bool noticeIsError: false
    readonly property var palettes: [
        { id: "tokyo-night", name: "Tokyo Night", kind: "Dark", background: "#1a1b26", accent: "#7aa2f7" },
        { id: "dracula", name: "Dracula", kind: "Dark", background: "#282a36", accent: "#bd93f9" },
        { id: "catppuccin-mocha", name: "Catppuccin Mocha", kind: "Dark", background: "#1e1e2e", accent: "#cba6f7" },
        { id: "catppuccin-macchiato", name: "Catppuccin Macchiato", kind: "Dark", background: "#24273a", accent: "#c6a0f6" },
        { id: "catppuccin-frappe", name: "Catppuccin Frappé", kind: "Dark", background: "#303446", accent: "#ca9ee6" },
        { id: "gruvbox-dark", name: "Gruvbox Dark", kind: "Dark", background: "#282828", accent: "#fabd2f" },
        { id: "astral", name: "Astral", kind: "Dark", background: "#121212", accent: "#8e92ff" },
        { id: "aurora", name: "Aurora", kind: "Dark", background: "#140f1f", accent: "#59c98d" },
        { id: "eldritch", name: "Eldritch", kind: "Dark", background: "#212337", accent: "#37f499" },
        { id: "monokai", name: "Monokai", kind: "Dark", background: "#0a1220", accent: "#78dce8" },
        { id: "moodpeak", name: "Moodpeak", kind: "Dark", background: "#181c22", accent: "#4ecdc4" },
        { id: "gruvbox-light", name: "Gruvbox Light", kind: "Light", background: "#fbf1c7", accent: "#9d0006" },
        { id: "solarized-light", name: "Solarized Light", kind: "Light", background: "#eee8d5", accent: "#005a80" },
        { id: "rose-pine-dawn", name: "Rosé Pine Dawn", kind: "Light", background: "#faf4ed", accent: "#907aa8" }
    ]
    readonly property string activeId: {
        if (Theme.currentThemeName !== "custom") return "";
        const path = SettingsData.customThemeFile || "";
        if (path.indexOf(themeDirectory) !== 0) return "";
        return path.slice(themeDirectory.length).replace(/\.json$/, "");
    }
    readonly property string activeName: {
        for (let i = 0; i < palettes.length; i++)
            if (palettes[i].id === activeId) return palettes[i].name;
        return "Choose a palette";
    }
    function applyPalette(palette) {
        const path = themeDirectory + palette.id + ".json";
        if (SettingsData.set("customThemeFile", path) === false) {
            noticeIsError = true;
            notice = "DMS could not change the theme setting.";
            return;
        }
        Theme.currentThemeCategory = "custom";
        Theme.setLightMode(palette.kind === "Light", true, false);
        Theme.switchTheme("custom", true, false);
        noticeIsError = false;
        notice = "Switching to " + palette.name + ".";
    }
    ccWidgetIcon: "palette"
    ccWidgetPrimaryText: "Theme Switcher"
    ccWidgetSecondaryText: activeName
    ccWidgetIsActive: activeId !== ""
    ccDetailHeight: 520
    ccDetailContent: Component { ThemePanel { controller: root; width: parent.width } }
    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS
            DankIcon { name: "palette"; color: Theme.primary; size: Theme.iconSize - 4 }
            StyledText { text: root.activeName; color: Theme.surfaceText; font.pixelSize: Theme.fontSizeSmall }
        }
    }
    verticalBarPill: Component { DankIcon { name: "palette"; color: Theme.primary; size: Theme.iconSize - 4 } }
    popoutWidth: 440
    popoutHeight: 560
    popoutContent: Component {
        PopoutComponent {
            headerText: "Theme Switcher"
            detailsText: "A palette for every mood."
            showCloseButton: true
            ThemePanel { controller: root; width: parent.width }
        }
    }
}
