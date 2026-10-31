import QtQuick
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Services
import qs.Modules.Plugins

PluginComponent {
    id: root

    property string pluginId: "videoDownloader"
    property var pluginService: null
    property var popoutService: null

    readonly property string scriptPath: "__HOME__/.local/bin/video-dl"

    property string selectedRes: "1080p"
    property string selectedCodec: "h264"
    property var resolutions: ["480p", "720p", "1080p", "1440p", "2160p"]
    property var formats: ["h264", "h265", "VP9", "AV1"]

    property var statusData: ({
        "phase": "idle",
        "detail": "Ready",
        "url": "",
        "resolution": "1080p",
        "codec": "h264",
        "filename": ""
    })
    property var history: []

    function refresh() {
        if (!statusProc.running)
            statusProc.running = true;
        if (!historyProc.running)
            historyProc.running = true;
    }

    function startDownload(url) {
        url = (url || "").trim();
        if (url === "") {
            ToastService.showError("Video Downloader", "Please enter or paste a video URL first.");
            return;
        }

        ToastService.showInfo("Video Downloader", "Starting " + root.selectedRes + " (" + root.selectedCodec + ") download…");

        Proc.runCommand("video-dl.download", [root.scriptPath, "download-bg", url, root.selectedRes, root.selectedCodec], (o, c) => {
            if (c === 0) {
                root.refresh();
            } else {
                ToastService.showError("Video Downloader", "Download failed to start: " + o.slice(-120));
            }
        });
    }

    function pasteClipboard(targetField) {
        Proc.runCommand("video-dl.paste", ["wl-paste", "--no-newline"], (out, code) => {
            if (code === 0 && out.trim() !== "") {
                const text = out.trim();
                targetField.text = text;
                ToastService.showInfo("Video Downloader", "Pasted URL from clipboard");
            } else {
                ToastService.showError("Video Downloader", "No text found on clipboard");
            }
        });
    }

    property Process statusProc: Process {
        command: [root.scriptPath, "status"]
        stdout: SplitParser {
            onRead: line => {
                const text = line.trim();
                if (text.startsWith("{")) {
                    try {
                        root.statusData = JSON.parse(text);
                    } catch (e) {}
                }
            }
        }
    }

    property Process historyProc: Process {
        command: [root.scriptPath, "history"]
        stdout: SplitParser {
            onRead: line => {
                const text = line.trim();
                if (text.startsWith("[")) {
                    try {
                        root.history = JSON.parse(text);
                    } catch (e) {}
                }
            }
        }
    }

    property Timer pollTimer: Timer {
        interval: 3000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    ccWidgetIcon: "video_download"
    ccWidgetPrimaryText: "Video Downloader"
    ccWidgetSecondaryText: statusData.phase === "downloading" ? statusData.detail : (selectedRes + " · " + selectedCodec)
    ccWidgetIsActive: statusData.phase === "downloading"

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                name: "video_download"
                color: root.statusData.phase === "downloading" ? Theme.primary : Theme.surfaceText
                size: Theme.iconSize - 4
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.statusData.phase === "downloading" ? "Downloading…" : "Video DL"
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        DankIcon {
            name: "video_download"
            color: root.statusData.phase === "downloading" ? Theme.primary : Theme.surfaceText
            size: Theme.iconSize - 4
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    ccDetailHeight: 390
    ccDetailContent: Component {
        Column {
            width: parent.width
            spacing: Theme.spacingS

            Row {
                width: parent.width
                spacing: Theme.spacingS

                DankIcon {
                    name: "video_download"
                    color: Theme.primary
                    size: Theme.iconSize + 2
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    width: parent.width - Theme.iconSize - 16
                    spacing: 2

                    StyledText {
                        text: "yt-dlp Video Downloader"
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Bold
                    }

                    StyledText {
                        text: "Save to ~/Descargas/Videos with chosen format & resolution"
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall - 2
                    }
                }
            }

            // URL input with Paste button
            Row {
                width: parent.width
                spacing: Theme.spacingS

                DankTextField {
                    id: ccUrlField
                    width: parent.width - 85
                    placeholderText: "Paste video URL (YouTube, Vimeo, Twitter, etc.)"
                    Accessible.name: "Video URL"
                }

                DankButton {
                    width: 75
                    text: "📋 Paste"
                    onClicked: root.pasteClipboard(ccUrlField)
                }
            }

            // Resolution selection
            StyledText {
                text: "Resolution:"
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
            }

            Row {
                width: parent.width
                spacing: 4

                Repeater {
                    model: root.resolutions

                    delegate: DankButton {
                        required property string modelData
                        width: (parent.width - 16) / 5
                        text: (root.selectedRes === modelData ? "● " : "") + modelData
                        onClicked: root.selectedRes = modelData
                    }
                }
            }

            // Format / Codec selection
            StyledText {
                text: "Format (Codec):"
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
            }

            Row {
                width: parent.width
                spacing: 4

                Repeater {
                    model: root.formats

                    delegate: DankButton {
                        required property string modelData
                        width: (parent.width - 12) / 4
                        text: (root.selectedCodec === modelData ? "● " : "") + modelData
                        onClicked: root.selectedCodec = modelData
                    }
                }
            }

            // Download Action Button
            DankButton {
                width: parent.width
                text: root.statusData.phase === "downloading" ? "⏳ Downloading in background…" : "⬇ Download (" + root.selectedRes + " · " + root.selectedCodec + ")"
                onClicked: {
                    root.startDownload(ccUrlField.text);
                    ccUrlField.text = "";
                }
            }

            // Status message
            StyledText {
                width: parent.width
                text: "Status: " + root.statusData.detail
                color: root.statusData.phase === "error" ? Theme.error : Theme.surfaceVariantText
                font.pixelSize: Theme.fontSizeSmall - 2
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }
    }

    popoutWidth: 440
    popoutHeight: 460
    popoutContent: Component {
        PopoutComponent {
            headerText: "Video Downloader"
            detailsText: "High-resolution video downloader powered by yt-dlp"
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingS

                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    DankTextField {
                        id: popUrlField
                        width: parent.width - 85
                        placeholderText: "Paste video URL here…"
                        Accessible.name: "Video URL"
                    }

                    DankButton {
                        width: 75
                        text: "📋 Paste"
                        onClicked: root.pasteClipboard(popUrlField)
                    }
                }

                StyledText {
                    text: "Max Resolution"
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                }

                Row {
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: root.resolutions

                        delegate: DankButton {
                            required property string modelData
                            width: (parent.width - 16) / 5
                            text: (root.selectedRes === modelData ? "● " : "") + modelData
                            onClicked: root.selectedRes = modelData
                        }
                    }
                }

                StyledText {
                    text: "Video Format / Codec"
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                }

                Row {
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: root.formats

                        delegate: DankButton {
                            required property string modelData
                            width: (parent.width - 12) / 4
                            text: (root.selectedCodec === modelData ? "● " : "") + modelData
                            onClicked: root.selectedCodec = modelData
                        }
                    }
                }

                DankButton {
                    width: parent.width
                    text: root.statusData.phase === "downloading" ? "⏳ Downloading…" : "⬇ Download Video (" + root.selectedRes + " · " + root.selectedCodec + ")"
                    onClicked: {
                        root.startDownload(popUrlField.text);
                        popUrlField.text = "";
                    }
                }

                StyledText {
                    width: parent.width
                    text: "Status: " + root.statusData.detail
                    color: root.statusData.phase === "error" ? Theme.error : Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall - 2
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                StyledText {
                    width: parent.width
                    text: "Recent Downloads (" + root.history.length + ")"
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                    visible: root.history.length > 0
                }

                Repeater {
                    model: root.history.slice(0, 3)

                    delegate: Row {
                        required property var modelData
                        width: parent.width
                        spacing: Theme.spacingXS

                        DankIcon {
                            name: "check_circle"
                            size: 16
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            width: parent.width - 24
                            text: (modelData.title || "Video") + " (" + (modelData.resolution || "") + " · " + (modelData.codec || "") + ")"
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall - 2
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }
}
