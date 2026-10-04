// The pages, as a row of tabs with the game's menu tab icons.
import QtQuick

Row {
    id: tabs
    property var pages: []            // [{title, icon}]
    property int current: 0
    signal picked(int index)
    spacing: 8 * Ui.s
    Repeater {
        model: tabs.pages
        Rectangle {
            id: t
            required property int index
            required property var modelData
            readonly property bool on: index === tabs.current
            width: (tabs.width - tabs.spacing * (tabs.pages.length - 1)) / tabs.pages.length
            height: tabs.height
            radius: 10 * Ui.s
            color: tap.pressed ? Ui.pressed : on ? Ui.paper : Ui.paperDark
            border { color: on ? Ui.accent : Ui.wood; width: (on ? 6 : 4) * Ui.s }
            Column {
                anchors.centerIn: parent
                spacing: 2 * Ui.s
                Pixel {
                    anchors.horizontalCenter: parent.horizontalCenter
                    sprite: t.modelData.icon || ""
                    width: 48 * Ui.s
                    height: 48 * Ui.s
                    fillMode: Image.Stretch
                    visible: status === Image.Ready
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: t.modelData.title
                    size: 24
                    bold: t.on
                }
            }
            TapHandler {
                id: tap
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onTapped: tabs.picked(t.index)
            }
        }
    }
}
