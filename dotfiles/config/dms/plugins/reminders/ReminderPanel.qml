import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: panel
    required property var controller
    property int selectedMinutes: 15
    spacing: Theme.spacingS

    Connections {
        target: panel.controller
        function onReminderAdded() { titleField.text = ""; dateField.text = ""; }
    }

    Rectangle {
        width: parent.width
        height: 70
        radius: 16
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Theme.surfaceVariant }
            GradientStop { position: 1; color: Theme.surface }
        }
        Rectangle { width: 4; height: parent.height - 20; radius: 2; anchors.left: parent.left; anchors.leftMargin: 5; anchors.verticalCenter: parent.verticalCenter; color: Theme.primary }
        Row {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12
            DankIcon { name: "notifications_active"; color: Theme.primary; size: 32; anchors.verticalCenter: parent.verticalCenter }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                StyledText { text: "A little nudge, right on time"; color: Theme.surfaceText; font.pixelSize: Theme.fontSizeMedium; font.weight: Font.Bold }
                StyledText { text: panel.controller.reminders.length + " on your list"; color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall }
            }
        }
    }
    DankTextField {
        id: titleField
        width: parent.width
        enabled: !panel.controller.busy
        placeholderText: "What would you like to remember?"
        Accessible.name: "Reminder title"
    }
    StyledText { text: "Remind me in"; color: Theme.surfaceText; font.pixelSize: Theme.fontSizeSmall; font.weight: Font.Medium }
    Row {
        width: parent.width
        spacing: 4
        Repeater {
            model: [{label:"5 min", value:5}, {label:"15 min", value:15}, {label:"30 min", value:30}, {label:"1 hour", value:60}]
            delegate: DankButton {
                required property var modelData
                width: (panel.width - 12) / 4
                enabled: !panel.controller.busy
                text: (panel.selectedMinutes === modelData.value ? "● " : "") + modelData.label
                Accessible.name: modelData.label + (panel.selectedMinutes === modelData.value ? ", selected" : "")
                onClicked: { panel.selectedMinutes = modelData.value; dateField.text = ""; }
            }
        }
    }
    DankTextField {
        id: dateField
        width: parent.width
        enabled: !panel.controller.busy
        placeholderText: "Or date and time: YYYY-MM-DD HH:MM"
        Accessible.name: "Optional local date and time, year month day hour minute"
    }
    DankButton {
        width: parent.width
        text: panel.controller.busy ? "Scheduling…" : "✦ Add reminder"
        enabled: !panel.controller.busy
        onClicked: panel.controller.add(titleField.text, dateField.text, panel.selectedMinutes)
    }
    StyledText {
        width: parent.width
        visible: panel.controller.notice !== ""
        text: panel.controller.notice
        color: panel.controller.noticeIsError ? Theme.error : Theme.primary
        wrapMode: Text.WordWrap
        font.pixelSize: Theme.fontSizeSmall
        Accessible.role: Accessible.StaticText
    }
    StyledText { text: "UP NEXT"; color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall; font.weight: Font.Bold; font.letterSpacing: 1.2 }
    StyledText {
        width: parent.width
        visible: panel.controller.reminders.length === 0
        text: "Nothing scheduled yet. Add a reminder to get started."
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
        font.pixelSize: Theme.fontSizeSmall
    }
    Flickable {
        width: parent.width
        height: Math.min(180, reminderList.implicitHeight)
        contentHeight: reminderList.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Column {
            id: reminderList
            width: parent.width
            spacing: 6
            Repeater {
                model: panel.controller.reminders
                delegate: Rectangle {
                    required property var modelData
                    width: reminderList.width
                    height: itemContent.implicitHeight + 20
                    radius: 12
                    color: Theme.surfaceVariant
                    Column {
                        id: itemContent
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                        spacing: 4
                        StyledText { width: parent.width; text: modelData.title; color: Theme.surfaceText; font.weight: Font.Medium; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight }
                        StyledText { width: parent.width; text: (modelData.notified ? "Due · " : "Scheduled · ") + panel.controller.dateLabel(modelData.due); color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall; elide: Text.ElideRight }
                        Row {
                            spacing: 4
                            DankButton { text: "Done"; Accessible.name: "Complete " + modelData.title; enabled: !panel.controller.busy; onClicked: panel.controller.runAction("complete", ["done", modelData.id], "Reminder completed.") }
                            DankButton { text: "+10 min"; Accessible.name: "Snooze " + modelData.title + " for 10 minutes"; enabled: !panel.controller.busy; onClicked: panel.controller.runAction("snooze", ["snooze", modelData.id, "10"], "Snoozed for 10 minutes.") }
                            DankButton { text: "Delete"; Accessible.name: "Delete " + modelData.title; enabled: !panel.controller.busy; onClicked: panel.controller.runAction("delete", ["delete", modelData.id], "Reminder deleted.") }
                        }
                    }
                }
            }
        }
    }
}
