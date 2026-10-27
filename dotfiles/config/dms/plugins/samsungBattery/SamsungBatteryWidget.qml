import QtQuick
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Services
import qs.Modules.Plugins

PluginComponent {
    id: root

    property string pluginId: "samsungBattery"
    property var pluginService: null
    property var popoutService: null

    property var phoneData: ({
        "name": "Samsung Galaxy A55 5G",
        "connected": false,
        "level": -1,
        "charging": false,
        "source": "none"
    })

    property var watchData: ({
        "name": "Galaxy Watch 7",
        "connected": false,
        "level": -1,
        "charging": false,
        "source": "none"
    })

    property string summary: "No Samsung devices connected"
    property bool hasData: false
    property bool isDemo: false

    readonly property string scriptPath: "__HOME__/.local/bin/samsung-battery"

    function refresh() {
        if (statusProc.running)
            return;
        statusProc.running = true;
    }

    function batteryColor(level) {
        if (level < 0) return Theme.surfaceVariantText;
        if (level <= 20) return Theme.errorText;
        if (level <= 45) return Theme.warningText;
        return Theme.primary;
    }

    function toggleDemo() {
        Proc.runCommand("samsungBattery.demo", [root.scriptPath, "demo", "toggle"], (o, c) => {
            root.refresh();
        });
    }

    function showPairGuide() {
        Proc.runCommand("samsungBattery.guide", [root.scriptPath, "pair-guide"], (o, c) => {
            ToastService.showInfo("Samsung Battery Setup", "Install KDE Connect on phone & watch (Wear OS) for live sync!");
        });
    }

    property Process statusProc: Process {
        command: [root.scriptPath, "status"]
        stdout: SplitParser {
            onRead: line => {
                const trimmed = line.trim();
                if (trimmed.startsWith("{")) {
                    try {
                        const data = JSON.parse(trimmed);
                        if (data.phone) root.phoneData = data.phone;
                        if (data.watch) root.watchData = data.watch;
                        if (data.summary) root.summary = data.summary;
                        root.hasData = Boolean(data.has_data);
                        root.isDemo = Boolean(data.demo);
                    } catch (e) {
                        console.error("samsungBattery parse error:", e);
                    }
                }
            }
        }
    }

    property Timer pollTimer: Timer {
        interval: 6000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    ccWidgetIcon: "battery_charging_full"
    ccWidgetPrimaryText: "Samsung Battery"
    ccWidgetSecondaryText: root.summary + (root.isDemo ? " (Demo)" : "")
    ccWidgetIsActive: (root.phoneData && root.phoneData.charging) || (root.watchData && root.watchData.charging)

    onCcWidgetToggled: {
        root.refresh();
    }

    // Top / DankBar Pill (Horizontal)
    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingS

            // Phone Battery Badge
            Row {
                spacing: 3
                anchors.verticalCenter: parent.verticalCenter

                DankIcon {
                    name: "smartphone"
                    color: root.phoneData.connected ? root.batteryColor(root.phoneData.level) : Theme.surfaceVariantText
                    size: Theme.iconSize - 4
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: root.phoneData.connected && root.phoneData.level >= 0
                          ? (root.phoneData.level + "%" + (root.phoneData.charging ? "⚡" : ""))
                          : "--"
                    color: root.phoneData.connected ? Theme.surfaceText : Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: root.phoneData.connected ? Font.Medium : Font.Normal
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            StyledText {
                text: "·"
                color: Theme.surfaceVariantText
                font.pixelSize: Theme.fontSizeSmall
                anchors.verticalCenter: parent.verticalCenter
            }

            // Watch Battery Badge
            Row {
                spacing: 3
                anchors.verticalCenter: parent.verticalCenter

                DankIcon {
                    name: "watch"
                    color: root.watchData.connected ? root.batteryColor(root.watchData.level) : Theme.surfaceVariantText
                    size: Theme.iconSize - 4
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: root.watchData.connected && root.watchData.level >= 0
                          ? (root.watchData.level + "%" + (root.watchData.charging ? "⚡" : ""))
                          : "--"
                    color: root.watchData.connected ? Theme.surfaceText : Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: root.watchData.connected ? Font.Medium : Font.Normal
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Demo indicator
            StyledText {
                visible: root.isDemo
                text: "🧪"
                font.pixelSize: Theme.fontSizeSmall - 2
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // Vertical Bar Pill
    verticalBarPill: Component {
        Column {
            spacing: 2
            anchors.horizontalCenter: parent.horizontalCenter

            DankIcon {
                name: "smartphone"
                color: root.phoneData.connected ? root.batteryColor(root.phoneData.level) : Theme.surfaceVariantText
                size: Theme.iconSize - 6
                anchors.horizontalCenter: parent.horizontalCenter
            }

            DankIcon {
                name: "watch"
                color: root.watchData.connected ? root.batteryColor(root.watchData.level) : Theme.surfaceVariantText
                size: Theme.iconSize - 6
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    // Interactive Popout Panel
    popoutWidth: 380
    popoutHeight: 460
    popoutContent: Component {
        PopoutComponent {
            headerText: "Samsung Galaxy Battery"
            detailsText: root.isDemo ? "Demo preview mode active" : "Galaxy A55 5G & Galaxy Watch 7"
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingM

                // --- Phone Card ---
                StyledRect {
                    width: parent.width
                    height: 100
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh

                    Column {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingXS

                        Item {
                            width: parent.width
                            height: 24

                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.spacingS

                                DankIcon {
                                    name: "smartphone"
                                    color: root.phoneData.connected ? Theme.primary : Theme.surfaceVariantText
                                    size: Theme.iconSize
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: root.phoneData.name || "Samsung Galaxy A55 5G"
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.Medium
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            StyledText {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.phoneData.connected && root.phoneData.level >= 0
                                      ? (root.phoneData.level + "% " + (root.phoneData.charging ? "⚡ Charging" : ""))
                                      : "Disconnected"
                                color: root.phoneData.connected ? root.batteryColor(root.phoneData.level) : Theme.surfaceVariantText
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Bold
                            }
                        }

                        // Battery Level Progress Bar
                        StyledRect {
                            width: parent.width
                            height: 10
                            radius: 5
                            color: Theme.surfaceContainerLowest

                            StyledRect {
                                width: root.phoneData.connected && root.phoneData.level > 0
                                       ? Math.max(8, parent.width * (root.phoneData.level / 100))
                                       : 0
                                height: parent.height
                                radius: 5
                                color: root.batteryColor(root.phoneData.level)
                            }
                        }

                        StyledText {
                            text: "Source: " + (root.phoneData.source || "None")
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall - 2
                        }
                    }
                }

                // --- Watch Card ---
                StyledRect {
                    width: parent.width
                    height: 100
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh

                    Column {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingXS

                        Item {
                            width: parent.width
                            height: 24

                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.spacingS

                                DankIcon {
                                    name: "watch"
                                    color: root.watchData.connected ? Theme.primary : Theme.surfaceVariantText
                                    size: Theme.iconSize
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: root.watchData.name || "Galaxy Watch 7"
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.Medium
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            StyledText {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.watchData.connected && root.watchData.level >= 0
                                      ? (root.watchData.level + "% " + (root.watchData.charging ? "⚡ Charging" : ""))
                                      : "Disconnected"
                                color: root.watchData.connected ? root.batteryColor(root.watchData.level) : Theme.surfaceVariantText
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Bold
                            }
                        }

                        // Battery Level Progress Bar
                        StyledRect {
                            width: parent.width
                            height: 10
                            radius: 5
                            color: Theme.surfaceContainerLowest

                            StyledRect {
                                width: root.watchData.connected && root.watchData.level > 0
                                       ? Math.max(8, parent.width * (root.watchData.level / 100))
                                       : 0
                                height: parent.height
                                radius: 5
                                color: root.batteryColor(root.watchData.level)
                            }
                        }

                        StyledText {
                            text: "Source: " + (root.watchData.source || "None")
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall - 2
                        }
                    }
                }

                // --- Action Buttons ---
                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    DankButton {
                        width: (parent.width - Theme.spacingS) / 2
                        text: "🔄 Refresh"
                        onClicked: {
                            root.refresh();
                            ToastService.showInfo("Samsung Battery", "Re-probing devices…");
                        }
                    }

                    DankButton {
                        width: (parent.width - Theme.spacingS) / 2
                        text: root.isDemo ? "🧪 Live Mode" : "🧪 Demo Mode"
                        onClicked: root.toggleDemo()
                    }
                }

                DankButton {
                    width: parent.width
                    text: "📖 Setup & Pairing Guide"
                    onClicked: root.showPairGuide()
                }
            }
        }
    }

    Component.onCompleted: {
        console.info("samsungBattery widget loaded");
        root.refresh();
    }
}
