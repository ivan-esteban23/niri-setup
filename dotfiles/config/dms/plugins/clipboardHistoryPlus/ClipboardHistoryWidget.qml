import QtQuick
import qs.Common
import qs.Widgets
import qs.Services
import qs.Modules.Plugins

PluginComponent {
    id: root

    ccWidgetIcon: "content_paste_search"
    ccWidgetPrimaryText: "Clipboard History"
    ccWidgetSecondaryText: "Browse & Save (Mod+V)"
    ccWidgetIsActive: true

    onCcWidgetToggled: {
        Proc.runCommand("clipHist.openModal", ["dms", "ipc", "call", "clipboard", "toggle"], (o, c) => {})
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS
            DankIcon {
                name: "content_paste_search"
                color: Theme.primary
                size: Theme.iconSize - 4
                anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                text: "History"
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS
            DankIcon {
                name: "content_paste_search"
                color: Theme.primary
                size: Theme.iconSize - 4
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    popoutWidth: 340
    popoutHeight: 280
    popoutContent: Component {
        PopoutComponent {
            headerText: "Clipboard History Manager"
            detailsText: "Browse, restore, or export your clipboard history"
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
                        text: "🔍 Open Full Clipboard History (Mod+V)"
                        color: Theme.primary
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Proc.runCommand("clipHist.toggle", ["dms", "ipc", "call", "clipboard", "toggle"], (o, c) => {})
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
                        text: "🖼️ Save Current Clipboard to ~/Pictures"
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeMedium
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Proc.runCommand(
                                "clipHist.savePic",
                                ["sh", "-c", "$HOME/.local/bin/clip-attach-helper paste-into \"$HOME/Pictures\""],
                                (o, c) => {}
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
                        text: "📄 Save Current Clipboard to ~/Documents"
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeMedium
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Proc.runCommand(
                                "clipHist.saveDoc",
                                ["sh", "-c", "$HOME/.local/bin/clip-attach-helper paste-into \"$HOME/Documents\""],
                                (o, c) => {}
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
                        text: "🗑️ Clear Clipboard History"
                        color: Theme.errorText
                        font.pixelSize: Theme.fontSizeMedium
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Proc.runCommand("clipHist.clear", ["dms", "clipboard", "clear"], (o, c) => {})
                            ToastService.showInfo("Clipboard History", "Cleared unpinned clipboard entries")
                        }
                    }
                }
            }
        }
    }
}
