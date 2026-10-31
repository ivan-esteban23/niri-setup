import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: panel
    required property var controller
    spacing: Theme.spacingS
    Rectangle {
        width: parent.width
        height: 68
        radius: 14
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Theme.surfaceVariant }
            GradientStop { position: 1; color: Theme.surface }
        }
        Row {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12
            DankIcon { name: "palette"; color: Theme.primary; size: 30; anchors.verticalCenter: parent.verticalCenter }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                StyledText { text: "Your desktop, your palette"; color: Theme.surfaceText; font.weight: Font.Bold }
                StyledText { text: "Current: " + panel.controller.activeName; color: Theme.surfaceText; font.pixelSize: Theme.fontSizeSmall }
            }
        }
    }
    StyledText { width: parent.width; text: "Choose a theme"; color: Theme.surfaceText; font.weight: Font.Bold }
    Flickable {
        width: parent.width
        height: Math.min(330, paletteList.height)
        contentHeight: paletteList.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Column {
            id: paletteList
            width: parent.width
            spacing: 5
            Repeater {
                model: panel.controller.palettes
                delegate: Rectangle {
                    required property var modelData
                    width: paletteList.width
                    height: 49
                    radius: 10
                    color: Theme.surfaceVariant
                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 5
                        spacing: 9
                        Rectangle {
                            width: 30; height: 30; radius: 8
                            anchors.verticalCenter: parent.verticalCenter
                            color: modelData.background
                            border.color: modelData.accent
                            border.width: 2
                            Rectangle { anchors.centerIn: parent; width: 10; height: 10; radius: 5; color: modelData.accent }
                        }
                        DankButton {
                            width: parent.width - 39
                            anchors.verticalCenter: parent.verticalCenter
                            text: (panel.controller.activeId === modelData.id ? "✓ " : "") + modelData.name + " · " + modelData.kind
                            Accessible.name: modelData.name + ", " + modelData.kind + (panel.controller.activeId === modelData.id ? ", selected" : "")
                            onClicked: panel.controller.applyPalette(modelData)
                        }
                    }
                }
            }
        }
    }
    StyledText {
        width: parent.width
        visible: panel.controller.notice !== ""
        text: panel.controller.notice
        color: panel.controller.noticeIsError ? Theme.error : Theme.surfaceText
        font.pixelSize: Theme.fontSizeSmall
        wrapMode: Text.WordWrap
        Accessible.role: Accessible.StaticText
    }
}
