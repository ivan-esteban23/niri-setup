import QtQuick
import qs.Common
import qs.Widgets
import qs.Services
import qs.Modules.Plugins

PluginComponent {
    id: root

    property bool isEnabled: pluginData.isEnabled !== undefined ? pluginData.isEnabled : true
    property string lastAttachedName: "Ready"

    ccWidgetIcon: "attach_file"
    ccWidgetPrimaryText: "Nautilus Attach"
    ccWidgetSecondaryText: isEnabled ? "Auto-Bridge Active" : "Paused"
    ccWidgetIsActive: isEnabled

    onCcWidgetToggled: {
        isEnabled = !isEnabled
        if (pluginService) {
            pluginService.savePluginData("nautilusClipboardAttach", "isEnabled", isEnabled)
        }
        const stateStr = isEnabled ? "true" : "false"
        Proc.runCommand(
            "nautilusAttach.toggle",
            ["sh", "-c", `mkdir -p ~/.cache/nautilus-clipboard-bridge && printf '{"enabled": %s}\\n' ${stateStr} > ~/.cache/nautilus-clipboard-bridge/config.json`],
            (out, code) => {}
        )
        ToastService.showInfo("Nautilus Clipboard Attach", isEnabled ? "Auto-Attach Bridge enabled" : "Auto-Attach Bridge paused")
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS
            DankIcon {
                name: "attach_file"
                color: root.isEnabled ? Theme.primary : Theme.surfaceVariantText
                size: Theme.iconSize - 4
                anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                text: "Attach"
                color: root.isEnabled ? Theme.surfaceText : Theme.surfaceVariantText
                font.pixelSize: Theme.fontSizeSmall
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS
            DankIcon {
                name: "attach_file"
                color: root.isEnabled ? Theme.primary : Theme.surfaceVariantText
                size: Theme.iconSize - 4
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    popoutWidth: 340
    popoutHeight: 230
    popoutContent: Component {
        PopoutComponent {
            headerText: "Nautilus Clipboard Attach"
            detailsText: "Copy any file or image in Nautilus (Ctrl+C or Right-Click) to attach here"
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingS

                StyledRect {
                    width: parent.width
                    height: 40
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh

                    StyledText {
                        anchors.centerIn: parent
                        text: "📎 Convert Copied Nautilus File Now"
                        color: Theme.primary
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Proc.runCommand(
                                "nautilusAttach.convertNow",
                                ["sh", "-c", "$HOME/.local/bin/clip-attach-helper convert-uri-list"],
                                (out, code) => {}
                            )
                        }
                    }
                }

                StyledRect {
                    width: parent.width
                    height: 40
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh

                    StyledText {
                        anchors.centerIn: parent
                        text: "📂 Open Nautilus File Manager"
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeMedium
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Proc.runCommand("nautilusAttach.openNautilus", ["nautilus"], (o, c) => {})
                        }
                    }
                }
            }
        }
    }
}
