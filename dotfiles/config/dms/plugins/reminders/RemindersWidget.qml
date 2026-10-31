import QtQuick
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Services
import qs.Modules.Plugins

PluginComponent {
    id: root
    property string pluginId: "reminders"
    property var pluginService: null
    property var popoutService: null
    readonly property string scriptPath: "__HOME__/.local/bin/niri-reminders"
    property var reminders: []
    property bool busy: false
    property string notice: ""
    property bool noticeIsError: false
    signal reminderAdded()

    function refresh() {
        if (!statusProc.running)
            statusProc.running = true;
    }
    function runAction(action, args, success) {
        if (root.busy) return;
        root.busy = true;
        root.notice = "";
        Proc.runCommand("reminders." + action, [root.scriptPath].concat(args), (output, code) => {
            root.busy = false;
            root.noticeIsError = code !== 0;
            root.notice = code === 0 ? success : "Could not " + action + " reminder. Check the date and try again.";
            if (code === 0 && action === "add") root.reminderAdded();
            root.refresh();
        });
    }
    function add(title, when, duration) {
        const clean = title.trim();
        if (!clean) {
            root.noticeIsError = true;
            root.notice = "Add a reminder first.";
            return;
        }
        const args = ["add"];
        if (when.trim())
            args.push("--at", when.trim());
        else
            args.push("--in", String(duration));
        args.push("--", clean);
        root.runAction("add", args, "Reminder scheduled.");
    }
    function dateLabel(seconds) {
        const due = new Date(seconds * 1000);
        return due.toLocaleString(Qt.locale(), "ddd, MMM d · h:mm AP");
    }

    property Process statusProc: Process {
        command: [root.scriptPath, "list"]
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.noticeIsError = true;
                root.notice = "Could not read reminders. Check the local reminder service.";
            }
        }
        stdout: SplitParser {
            onRead: line => {
                try {
                    const data = JSON.parse(line.trim());
                    if (data.reminders !== undefined) root.reminders = data.reminders;
                } catch (e) {
                    root.noticeIsError = true;
                    root.notice = "Could not read reminders.";
                }
            }
        }
    }
    property Timer refreshTimer: Timer {
        interval: 15000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }
    Component.onCompleted: root.refresh()

    ccWidgetIcon: "notifications_active"
    ccWidgetPrimaryText: "Reminders"
    ccWidgetSecondaryText: root.reminders.length ? root.reminders.length + " upcoming" : "Your next moment, planned"
    ccWidgetIsActive: root.reminders.length > 0
    ccDetailHeight: 520
    ccDetailContent: Component {
        ReminderPanel { controller: root; width: parent.width }
    }
    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS
            DankIcon { name: "notifications_active"; color: Theme.primary; size: Theme.iconSize - 4 }
            StyledText { text: root.reminders.length ? String(root.reminders.length) : "Reminders"; color: Theme.surfaceText; font.pixelSize: Theme.fontSizeSmall }
        }
    }
    verticalBarPill: Component {
        DankIcon { name: "notifications_active"; color: Theme.primary; size: Theme.iconSize - 4 }
    }
    popoutWidth: 440
    popoutHeight: 580
    popoutContent: Component {
        PopoutComponent {
            headerText: "Reminders"
            detailsText: "Make room for what matters."
            showCloseButton: true
            ReminderPanel { controller: root; width: parent.width }
        }
    }
}
