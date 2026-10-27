import QtQuick
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Services
import qs.Modules.Plugins

PluginComponent {
    id: root

    property string pluginId: "imgPrompt"
    property var pluginService: null
    property var popoutService: null

    // Mirrors ~/.cache/img-prompt/state.json
    property string phase: "idle"
   property string detail: ""

    readonly property string scriptPath: "__HOME__/.local/bin/img-prompt"

    function phaseLabel() {
        switch (phase) {
            case "analyzing": return "ChatGPT analyzing…";
            case "busy": return "Busy…";
            case "staged": return "Ready → build prompt";
            case "done": return "Prompt in clipboard";
            case "error": return "Error";
            default: return "Attach image first";
        }
    }

    function runScript(mode) {
        Proc.runCommand("imgPrompt." + mode, ["sh", "-c", root.scriptPath + " " + mode], (o, c) => {})
    }

    // Poll state file every 2 s
    property Process stateProc: Process {
        command: ["/bin/sh", "-c", root.scriptPath + " status 2>/dev/null"]
        stdout: SplitParser {
            onRead: line => {
                // first line is JSON {"phase":…,"detail":…}
                if (root.phase === "idle" && line.trim().startsWith("{")) {
                    try {
                        const st = JSON.parse(line.trim());
                        root.phase = st.phase || "idle";
                        root.detail = st.detail ? String(st.detail).replace(/^"|"$/g, "") : "";
                    } catch (e) {}
                } else if (line.startsWith("image: ")) {
                    if (root.phase === "idle")
                        root.phase = "staged";
                }
            }
        }
    }

    property Timer stateTimer: Timer {
        interval: 2000
        repeat: true
        running: true

        onTriggered: {
            root.phase = "idle";
            root.detail = "";
            root.stateProc.running = true;
        }
    }

    ccWidgetIcon: "image_search"
    ccWidgetPrimaryText: "Image Prompt"
    ccWidgetSecondaryText: phase !== "idle" ? phaseLabel() : "Attach (Mod+Shift+B) · Build (Mod+Shift+G)"
    ccWidgetIsActive: phase === "analyzing" || phase === "busy"

    onCcWidgetToggled: {
        root.runScript("auto");
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                name: "image_search"
                color: root.phase === "error" ? Theme.errorText : Theme.primary
                size: Theme.iconSize - 4
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.phase === "done" ? "Prompt ✓" : phaseLabel()
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
                name: "image_search"
                color: root.phase === "error" ? Theme.errorText : Theme.primary
                size: Theme.iconSize - 4
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    popoutWidth: 360
    popoutHeight: 320
    popoutContent: Component {
        PopoutComponent {
            headerText: "Image Prompt Builder"
            detailsText: "Framework analysis → ChatGPT image prompt"
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingS

                StyledText {
                    width: parent.width
                    text: "Status: " + (root.phase !== "idle" ? root.phaseLabel() + (root.detail !== "" ? " — " + root.detail : "") : "attach a reference to begin")
                    color: root.phase === "error" ? Theme.errorText : Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.WordWrap
                }

                StyledRect {
                    width: parent.width
                    height: 40
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh

                    StyledText {
                        anchors.centerIn: parent
                        text: "📎 Attach from Clipboard (Mod+Shift+B)"
                        color: Theme.primary
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.runScript("stage");
                            ToastService.showInfo("Image Prompt", "Staging image from clipboard…");
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
                        text: "✨ Build ChatGPT Prompt (Mod+Shift+G)"
                        color: Theme.primary
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.runScript("run");
                            ToastService.showInfo("Image Prompt", "Analyzing with ChatGPT… this takes a minute.");
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
                        text: "📋 Open Result in Notepad"
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeMedium
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Proc.runCommand("imgPrompt.open", ["dms", "ipc", "call", "notepad", "toggle"], (o, c) => {})
                            ToastService.showInfo("Image Prompt", "Result: ~/.cache/img-prompt/prompt.txt (already copied to clipboard)");
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        console.info("imgPrompt widget loaded");
        root.stateProc.running = true;
    }
}
