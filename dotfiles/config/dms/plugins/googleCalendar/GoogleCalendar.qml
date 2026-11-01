import QtQuick
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Services
import qs.Modules.Plugins

PluginComponent {
    id: root
    property string pluginId: "googleCalendar"
    property var pluginService: null
    property var popoutService: null
    property var data: ({status: "Loading calendar…", events: []})
    property int clockNow: Math.floor(Date.now() / 1000)
    property bool forceRefresh: false
    function refresh(force) {
        if (agenda.running) return
        root.forceRefresh = force
        agenda.running = true
    }
    function nextEvent() {
        const events = root.data.events || []
        for (let i = 0; i < events.length; i++)
            if (!events[i].allDay && events[i].end > root.clockNow && events[i].start < root.clockNow + 43200) return events[i]
        return null
    }
    function barLabel() {
        const event = nextEvent()
        if (!event) return "Calendar"
        const minutes = Math.ceil((event.start - root.clockNow) / 60)
        return event.title + (minutes <= 0 ? " · now" : " · " + minutes + "m")
    }
    function openUrl(url) {
        if (/^https:\/\//i.test(url)) Proc.runCommand("googleCalendar.open", ["xdg-open", url], (o, code) => {})
    }
    property Process agenda: Process {
        command: root.forceRefresh ? ["__HOME__/.local/bin/niri-gcal", "--refresh"] : ["__HOME__/.local/bin/niri-gcal"]
        stdout: SplitParser { onRead: line => { try { root.data = JSON.parse(line) } catch (e) { root.data = {status: "Could not read calendar data.", events: []} } } }
        onExited: (code, status) => { if (code !== 0) root.data = {status: "Calendar helper failed.", events: []} }
    }
    property Timer clockTimer: Timer { interval: 30000; repeat: true; running: true; onTriggered: { root.clockNow = Math.floor(Date.now() / 1000); root.refresh(false) } }
    Component.onCompleted: root.refresh(false)
    horizontalBarPill: Component {
        Row { spacing: Theme.spacingXS
            DankIcon { name: "event"; color: Theme.primary; size: Theme.iconSize - 4 }
            StyledText { text: root.barLabel(); color: Theme.surfaceText; font.pixelSize: Theme.fontSizeSmall; elide: Text.ElideRight; width: Math.min(implicitWidth, 160) }
        }
    }
    verticalBarPill: Component { DankIcon { name: "event"; color: Theme.primary; size: Theme.iconSize - 4 } }
    popoutWidth: 420
    popoutHeight: 520
    popoutContent: Component {
        PopoutComponent {
            headerText: "Google Calendar"
            detailsText: root.data.status
            showCloseButton: true
            Column {
                width: parent.width; spacing: Theme.spacingS
                StyledText { width: parent.width; visible: !(root.data.events || []).length; text: root.data.status === "Calendar synced" ? "No upcoming events." : root.data.status + " See the Google Calendar setup in the niri-setup README."; color: Theme.surfaceVariantText; wrapMode: Text.WordWrap }
                StyledText { width: parent.width; visible: root.data.status !== "Calendar synced" && (root.data.events || []).length > 0; text: root.data.status + " Showing cached events."; color: Theme.surfaceVariantText; wrapMode: Text.WordWrap }
                Flickable {
                    width: parent.width; height: Math.min(350, eventList.implicitHeight); contentHeight: eventList.implicitHeight; clip: true
                    Column {
                        id: eventList; width: parent.width; spacing: Theme.spacingS
                        Repeater {
                            model: root.data.events || []
                            delegate: Column {
                                required property var modelData
                                width: eventList.width; spacing: 4
                                StyledText { width: parent.width; text: modelData.title; color: Theme.surfaceText; font.weight: Font.Bold; wrapMode: Text.WordWrap }
                                StyledText { width: parent.width; text: new Date(modelData.start * 1000).toLocaleString(Qt.locale(), modelData.allDay ? "ddd, MMM d" : "ddd, MMM d · h:mm AP") + (modelData.allDay ? " · all day" : ""); color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall }
                                Row { spacing: Theme.spacingS
                                    DankButton { visible: !!modelData.meet; text: "Join"; onClicked: root.openUrl(modelData.meet) }
                                    DankButton { visible: !!modelData.link; text: "Details"; onClicked: root.openUrl(modelData.link) }
                                }
                            }
                        }
                    }
                }
                Row { width: parent.width; spacing: Theme.spacingS
                    DankButton { width: (parent.width - Theme.spacingS) / 2; text: agenda.running ? "Syncing…" : "Sync now"; enabled: !agenda.running; onClicked: root.refresh(true) }
                    DankButton { width: (parent.width - Theme.spacingS) / 2; text: "Open Calendar"; onClicked: root.openUrl("https://calendar.google.com/") }
                }
            }
        }
    }
}
