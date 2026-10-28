import QtQuick
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Services
import qs.Modules.Plugins

PluginComponent {
    id: root

    property string pluginId: "dnsSwitcher"
    property var pluginService: null
    property var popoutService: null

    readonly property string scriptPath: "__HOME__/.local/bin/dns-switch"

    // Mirrors `dns-switch status`
    property var statusData: ({
        "provider": "isp",
        "label": "Reading DNS state…",
        "short": "…",
        "icon": "dns",
        "desc": "",
        "ipv4": [],
        "ipv6": [],
        "effective": [],
        "effective_ignored": [],
        "search": "",
        "drift": false,
        "desired": "",
        "tailscale_dns": false,
        "tailscale_wanted": false,
        "tailscale_installed": false,
        "magicdns_suffix": "",
        "magicdns_pending": false,
        "profiles": [],
        "devices": [],
        "providers": []
    })
    property bool applying: false
    property bool testing: false
    property var latency: []

    function refresh() {
        if (statusProc.running)
            return;
        statusProc.running = true;
    }

    function providerOf(id) {
        const list = root.statusData.providers || [];
        for (let i = 0; i < list.length; ++i)
            if (list[i].id === id)
                return list[i];
        return null;
    }

    function isCurrent(id) {
        return root.statusData.provider === id;
    }

    function needsAttention() {
        return root.statusData.drift || root.statusData.magicdns_pending;
    }

    function serversText(p) {
        const parts = [];
        if (p.ipv4 && p.ipv4.length > 0)
            parts.push(p.ipv4.join("   "));
        if (p.ipv6 && p.ipv6.length > 0)
            parts.push(p.ipv6.join("   "));
        return parts.length > 0 ? parts.join("  ·  ") : "router / DHCP supplied";
    }

    function statusLine() {
        if (root.applying)
            return "Applying…";
        if (root.statusData.magicdns_pending)
            return "MagicDNS pending — Tailscale is not serving resolv.conf";
        if (root.statusData.drift)
            return "Out of sync — re-apply to fix";
        const eff = (root.statusData.effective || []).join("   ");
        return eff === "" ? "No nameservers active" : eff;
    }

    function latencyText(id) {
        if (root.latency.length === 0)
            return "";
        const bestOf = fam => {
            let fastest = null;
            let failed = false;
            for (const r of root.latency) {
                if (r.provider !== id || r.family !== fam)
                    continue;
                if (r.ms === null || r.ms === undefined) {
                    failed = true;
                    continue;
                }
                fastest = (fastest === null) ? r.ms : Math.min(fastest, r.ms);
            }
            if (fastest !== null)
                return fastest + " ms";
            return failed ? "unreachable" : "";
        };
        const v4 = bestOf("ipv4");
        const v6 = bestOf("ipv6");
        if (v4 === "" && v6 === "")
            return "";
        return "probe — IPv4 " + v4 + (v6 === "" ? "" : "  ·  IPv6 " + v6);
    }

    function applyProvider(id) {
        if (root.applying || id === "")
            return;
        root.applying = true;
        Proc.runCommand("dnsSwitcher.apply", [root.scriptPath, "apply", id], (o, c) => {
            root.applying = false;
            const p = root.providerOf(id);
            if (c === 0)
                ToastService.showInfo("DNS Switcher", (p ? p.label : id) + " applied");
            else
                ToastService.showError("DNS Switcher", "Apply failed — " + o.slice(-160));
            root.refresh();
        });
    }

    function reapply() {
        const wanted = root.statusData.drift && root.statusData.desired !== ""
                       ? root.statusData.desired : root.statusData.provider;
        root.applyProvider(wanted);
    }

    function cycle() {
        if (root.applying)
            return;
        root.applying = true;
        Proc.runCommand("dnsSwitcher.cycle", [root.scriptPath, "cycle"], (o, c) => {
            root.applying = false;
            if (c === 0)
                ToastService.showInfo("DNS Switcher", o.split("\n")[0] || "Next provider applied");
            else
                ToastService.showError("DNS Switcher", "Cycle failed — " + o.slice(-120));
            root.refresh();
        });
    }

    function runTest() {
        if (root.testing)
            return;
        root.testing = true;
        root.latency = [];
        Proc.runCommand("dnsSwitcher.test", [root.scriptPath, "test"], (o, c) => {
            root.testing = false;
            const lines = o.trim().split("\n");
            if (c !== 0 || lines.length === 0) {
                ToastService.showError("DNS Switcher", "Probe failed — " + o.slice(-120));
                return;
            }
            try {
                root.latency = JSON.parse(lines[lines.length - 1]);
                ToastService.showInfo("DNS Switcher", "Measured " + root.latency.length + " nameservers");
            } catch (e) {
                ToastService.showError("DNS Switcher", "Could not read probe output");
            }
        });
    }

    property Process statusProc: Process {
        command: [root.scriptPath, "status"]

        stdout: SplitParser {
            onRead: line => {
                const text = line.trim();
                if (!text.startsWith("{"))
                    return;
                try {
                    root.statusData = JSON.parse(text);
                } catch (e) {
                    console.error("dnsSwitcher parse error:", e);
                }
            }
        }
    }

    property Timer statusTimer: Timer {
        interval: 8000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    // One provider row, reused by the Control Center detail and the bar popout.
    property Component providerRow: Component {
        StyledRect {
            id: providerCell
            required property var modelData

            width: parent ? parent.width : 0
            height: root.latencyText(modelData.id) === "" ? 58 : 76
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh

            Row {
                anchors.fill: parent
                anchors.margins: Theme.spacingS
                spacing: Theme.spacingS

                DankIcon {
                    name: root.isCurrent(modelData.id) ? modelData.icon : "radio_button_unchecked"
                    color: root.isCurrent(modelData.id) ? Theme.primary : Theme.surfaceVariantText
                    size: Theme.iconSize
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    id: cellColumn
                    width: providerCell.width - 120
                    spacing: 2

                    StyledText {
                        width: cellColumn.width
                        text: modelData.label
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: root.isCurrent(modelData.id) ? Font.Bold : Font.Medium
                        elide: Text.ElideRight
                    }

                    StyledText {
                        width: cellColumn.width
                        text: root.serversText(modelData)
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall - 2
                        elide: Text.ElideRight
                    }

                    StyledText {
                        width: cellColumn.width
                        visible: root.latencyText(modelData.id) !== ""
                        text: root.latencyText(modelData.id)
                        color: Theme.primary
                        font.pixelSize: Theme.fontSizeSmall - 2
                        elide: Text.ElideRight
                    }
                }

                DankIcon {
                    name: "check_circle"
                    visible: root.isCurrent(modelData.id)
                    color: Theme.primary
                    size: Theme.iconSize - 4
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: !root.applying
                onClicked: {
                    if (!root.isCurrent(modelData.id))
                        root.applyProvider(modelData.id);
                }
            }
        }
    }

    ccWidgetIcon: "dns"
    ccWidgetPrimaryText: "DNS · " + root.statusData.short
    ccWidgetSecondaryText: root.statusLine()
    ccWidgetIsActive: root.needsAttention()

    onCcWidgetToggled: {
        Proc.runCommand("dnsSwitcher.open", ["dms", "ipc", "call", "control-center", "openWith", "plugin_dnsSwitcher"], (o, c) => {
        });
    }

    ccDetailHeight: 210 + (root.statusData.providers || []).length * 64
    ccDetailContent: Component {
        Column {
            width: parent.width
            spacing: Theme.spacingS

            Row {
                width: parent.width
                spacing: Theme.spacingS

                DankIcon {
                    name: root.statusData.icon
                    color: Theme.primary
                    size: Theme.iconSize + 4
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    width: parent.width - Theme.iconSize - 16
                    spacing: 2

                    StyledText {
                        width: parent.width
                        text: root.statusData.label
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Bold
                    }

                    StyledText {
                        width: parent.width
                        text: root.statusData.desc
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall - 2
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                    }
                }
            }

            StyledText {
                width: parent.width
                text: "Active: " + root.statusLine()
                color: root.needsAttention() ? Theme.warningText : Theme.surfaceVariantText
                font.pixelSize: Theme.fontSizeSmall - 2
                wrapMode: Text.WordWrap
                maximumLineCount: 2
            }

            StyledText {
                width: parent.width
                visible: (root.statusData.effective_ignored || []).length > 0
                text: "glibc uses only the first 3 servers — ignored: " + root.statusData.effective_ignored.join(" ")
                color: Theme.surfaceVariantText
                font.pixelSize: Theme.fontSizeSmall - 2
                wrapMode: Text.WordWrap
            }

            StyledText {
                width: parent.width
                text: "Search domain: " + (root.statusData.search === "" ? "none" : root.statusData.search)
                      + "  ·  Profiles: " + (root.statusData.profiles || []).join(", ")
                color: Theme.surfaceVariantText
                font.pixelSize: Theme.fontSizeSmall - 2
                wrapMode: Text.WordWrap
                maximumLineCount: 2
            }

            Repeater {
                model: root.statusData.providers
                delegate: root.providerRow
            }

            DankButton {
                width: parent.width
                visible: root.needsAttention()
                text: "Re-apply " + root.statusData.label
                onClicked: root.reapply()
            }

            Row {
                width: parent.width
                spacing: Theme.spacingS

                DankButton {
                    width: (parent.width - Theme.spacingS * 2) / 3
                    text: root.applying ? "Working…" : "Cycle"
                    onClicked: root.cycle()
                }

                DankButton {
                    width: (parent.width - Theme.spacingS * 2) / 3
                    text: root.testing ? "Probing…" : "Test speed"
                    onClicked: root.runTest()
                }

                DankButton {
                    width: (parent.width - Theme.spacingS * 2) / 3
                    text: "Refresh"
                    onClicked: root.refresh()
                }
            }
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                name: "dns"
                color: root.needsAttention() ? Theme.warningText : Theme.primary
                size: Theme.iconSize - 4
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.statusData.short
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        DankIcon {
            name: "dns"
            color: root.needsAttention() ? Theme.warningText : Theme.primary
            size: Theme.iconSize - 4
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    popoutWidth: 420
    popoutHeight: 500
    popoutContent: Component {
        PopoutComponent {
            headerText: "DNS Switcher"
            detailsText: root.statusData.label
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingS

                StyledText {
                    width: parent.width
                    text: "IPv4 " + ((root.statusData.ipv4 || []).join(" ") || "auto")
                          + "   ·   IPv6 " + ((root.statusData.ipv6 || []).join(" ") || "auto")
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall - 2
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                }

                Repeater {
                    model: root.statusData.providers
                    delegate: root.providerRow
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    DankButton {
                        width: (parent.width - Theme.spacingS) / 2
                        text: root.testing ? "Probing…" : "Test speed"
                        onClicked: root.runTest()
                    }

                    DankButton {
                        width: (parent.width - Theme.spacingS) / 2
                        text: root.applying ? "Working…" : "Cycle"
                        onClicked: root.cycle()
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        console.info("dnsSwitcher widget loaded");
        root.refresh();
    }
}
