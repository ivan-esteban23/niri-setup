import QtQuick
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root
    property string pluginId: "aiAgents"
    property var pluginService: null
    property var popoutService: null
    property var antigravity: ({status: "Reading Antigravity…", limits: []})
    property var data: ({status: "Reading Codex limits…", limits: []})
    function refresh() { if (!usage.running) usage.running = true; if (!agUsage.running) agUsage.running = true }
    function resetText(timestamp) {
        return timestamp ? "Resets " + new Date(timestamp * 1000).toLocaleString(Qt.locale(), "MMM d · h:mm AP") : "Reset time unavailable"
    }
    property Process usage: Process {
        command: ["__HOME__/.local/bin/ai-agent-usage"]
        stdout: SplitParser { onRead: line => { try { root.data = JSON.parse(line) } catch (e) { root.data = {status: "Could not read usage data.", limits: []} } } }
        onExited: (code, status) => { if (code !== 0) root.data = {status: "Usage helper failed. Check installation.", limits: []} }
    }
    property Process agUsage: Process {
        command: ["__HOME__/.local/bin/antigravity-agent-usage"]
        stdout: SplitParser { onRead: line => { try { root.antigravity = JSON.parse(line) } catch (e) { root.antigravity = {status: "Could not read Antigravity snapshot.", limits: []} } } }
        onExited: (code, status) => { if (code !== 0) root.antigravity = {status: "Antigravity helper failed.", limits: []} }
    }
    property Timer timer: Timer { interval: 300000; repeat: true; running: true; onTriggered: root.refresh() }
    Component.onCompleted: root.refresh()
    horizontalBarPill: Component {
        Row { spacing: Theme.spacingXS
            DankIcon { name: "smart_toy"; color: Theme.primary; size: Theme.iconSize - 4 }
            StyledText { text: "AI"; color: Theme.surfaceText; font.pixelSize: Theme.fontSizeSmall }
        }
    }
    verticalBarPill: Component { DankIcon { name: "smart_toy"; color: Theme.primary; size: Theme.iconSize - 4 } }
    popoutWidth: 400
    popoutHeight: 410
    popoutContent: Component {
        PopoutComponent {
            headerText: "AI Agents"
            detailsText: "Subscription usage"
            showCloseButton: true
            Column {
                width: parent.width; spacing: Theme.spacingS
                StyledText { text: "Codex"; color: Theme.surfaceText; font.weight: Font.Bold }
                StyledText { width: parent.width; text: root.data.status; color: Theme.surfaceVariantText; wrapMode: Text.WordWrap }
                Flickable {
                    width: parent.width; height: Math.min(245, cards.implicitHeight); contentHeight: cards.implicitHeight; clip: true
                    Column {
                        id: cards; width: parent.width; spacing: Theme.spacingS
                        Repeater {
                            model: root.data.limits.concat([{section: true, label: "Antigravity · " + root.antigravity.status}]).concat(root.antigravity.limits)
                            delegate: Column {
                                required property var modelData
                                width: cards.width; spacing: 5
                                StyledText { width: parent.width; text: modelData.section ? modelData.label : modelData.label + " · " + modelData.used + "% used"; color: Theme.surfaceText; elide: Text.ElideRight }
                                Rectangle { visible: !modelData.section; width: parent.width; height: visible ? 8 : 0; radius: 4; color: Theme.surfaceVariant
                                    Rectangle { width: parent.width * modelData.used / 100; height: parent.height; radius: 4; color: Theme.primary }
                                }
                                StyledText { visible: !modelData.section; text: root.resetText(modelData.reset); color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall }
                            }
                        }
                    }
                }
                DankButton { width: parent.width; text: root.usage.running ? "Refreshing…" : "Refresh"; enabled: !root.usage.running; onClicked: root.refresh() }
            }
        }
    }
}
