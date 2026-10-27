import QtQuick
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Services
import qs.Modules.Plugins

PluginComponent {
    id: root

    property string pluginId: "webappManager"
    property var pluginService: null
    property var popoutService: null

    // Installed web apps (mirrors ~/.cache/webapps/apps.json)
    property var apps: []
    property int appCount: 0

    readonly property string scriptPath: "__HOME__/.local/bin/webapp"
    readonly property string appsFile: "__HOME__/.cache/webapps/apps.json"

    function refresh() {
        if (appsProc.running)
            return;
        appsProc.running = true;
    }

    function doInstall(url, name) {
        url = (url || "").trim();
        if (url === "") {
            ToastService.showError("WebApp Manager", "Enter a website URL first (e.g. youtube.com)");
            return;
        }
        name = (name || "").trim();
        Proc.runCommand("webapp.install", [root.scriptPath, "install", url, name], (o, c) => {
            if (c === 0) {
                ToastService.showInfo("WebApp Manager", "Installed — find it in Spotlight as '… (WebApp)'");
                root.refresh();
            } else {
                ToastService.showError("WebApp Manager", "Install failed — " + o.slice(-160));
            }
        });
    }

    function install() {
        const url = urlField.text.trim();
        const name = nameField.text.trim();
        root.doInstall(url, name);
        urlField.text = "";
        nameField.text = "";
    }

    function removeWebApp(app) {
        Proc.runCommand("webapp.remove", [root.scriptPath, "remove", app], (o, c) => {
            if (c === 0) {
                ToastService.showInfo("WebApp Manager", "Removed");
                root.refresh();
            } else {
                ToastService.showError("WebApp Manager", "Remove failed — " + o.slice(-160));
            }
        });
    }

    // Poll the apps index every 4 s
    property Process appsProc: Process {
        command: ["jq", "-c", ".", root.appsFile]

        stdout: SplitParser {
            onRead: line => {
                try {
                    root.apps = JSON.parse(line.trim()) || [];
                    root.appCount = root.apps.length;
                } catch (e) {}
            }
        }
    }

    property Timer appsTimer: Timer {
        interval: 4000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    ccWidgetIcon: "web_asset"
    ccWidgetPrimaryText: "WebApps"
    ccWidgetSecondaryText: appCount === 0 ? "Install any site as an app" : appCount + " web app" + (appCount === 1 ? "" : "s") + " installed"
    ccWidgetIsActive: false

    onCcWidgetToggled: {
        ToastService.showInfo("WebApp Manager", "Open the detail panel to install or remove web apps.");
    }

    // Control Center detail page (opened via Mod+G / "openWith") — this is NOT
    // popoutContent: CC widgets render their detail through ccDetailContent.
    ccDetailHeight: Math.min(560, 280 + root.appCount * 44)
    ccDetailContent: Component {
        Column {
            width: parent.width
            spacing: Theme.spacingS

            DankTextField {
                width: parent.width
                placeholderText: "Website URL — e.g. youtube.com or https://app.whatsapp.com"
                Accessible.name: "Website URL"
                id: ccUrlField
            }

            DankTextField {
                width: parent.width
                placeholderText: "Custom name (optional — taken from the domain)"
                Accessible.name: "WebApp name"
                id: ccNameField
            }

            DankButton {
                width: parent.width
                text: "⚡ Install as Web App"
                onClicked: {
                    root.doInstall(ccUrlField.text, ccNameField.text);
                    ccUrlField.text = "";
                    ccNameField.text = "";
                }
            }

            StyledText {
                width: parent.width
                text: "Installed web apps (" + root.appCount + ") — click Remove to uninstall"
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
            }

            Repeater {
                model: root.apps

                delegate: Row {
                    required property var modelData
                    width: parent.width
                    spacing: Theme.spacingS

                    DankIcon {
                        name: "public"
                        color: Theme.primary
                        size: Theme.iconSize - 6
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        width: parent.width - 110
                        text: (modelData.name || "?") + " — " + (modelData.url || "")
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeSmall
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    DankButton {
                        text: "Remove"
                        onClicked: root.removeWebApp(modelData.slug)
                    }
                }
            }

            StyledText {
                width: parent.width
                visible: root.appCount === 0
                text: "No web apps yet. Type a URL above and hit Install.\nLaunchers appear immediately in Spotlight and your app menu."
                color: Theme.surfaceVariantText
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
            }
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                name: "web_asset"
                color: Theme.primary
                size: Theme.iconSize - 4
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.appCount > 0 ? String(root.appCount) + " webapps" : "Webapps"
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        DankIcon {
            name: "web_asset"
            color: Theme.primary
            size: Theme.iconSize - 4
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    popoutWidth: 420
    popoutHeight: 460
    popoutContent: Component {
        PopoutComponent {
            headerText: "WebApp Manager"
            detailsText: "Any website → Brave Origin app window. Remove what you don't want."
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingS

                DankTextField {
                    width: parent.width
                    placeholderText: "Website URL — e.g. youtube.com or https://app.whatsapp.com"
                    Accessible.name: "Website URL"
                    id: urlField
                }

                DankTextField {
                    width: parent.width
                    placeholderText: "Custom name (optional — taken from the domain)"
                    Accessible.name: "WebApp name"
                    id: nameField
                }

                DankButton {
                    width: parent.width
                    text: "⚡ Install as Web App"
                    onClicked: root.install()
                }

                StyledText {
                    width: parent.width
                    text: "Installed web apps (" + root.appCount + ")"
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium
                }

                Repeater {
                    model: root.apps

                    delegate: Row {
                        required property var modelData
                        width: parent.width
                        spacing: Theme.spacingS

                        DankIcon {
                            name: "public"
                            color: Theme.primary
                            size: Theme.iconSize - 6
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            width: parent.width - 48
                            text: (modelData.name || "?") + " — " + (modelData.url || "")
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 0
                        }

                        DankButton {
                            text: "Remove"
                            onClicked: root.removeWebApp(modelData.slug)
                        }
                    }
                }

                StyledText {
                    width: parent.width
                    visible: root.appCount === 0
                    text: "No web apps yet. Type a URL above and hit Install.\nLaunchers appear immediately in Spotlight and your app menu."
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    Component.onCompleted: {
        console.info("webappManager widget loaded");
        root.refresh();
    }
}
