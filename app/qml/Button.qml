// A wooden button. Taps on release, inside it.
import QtQuick

Rectangle {
    id: btn
    property string text
    property string icon            // a sprite id, drawn left of the text
    property bool active: false
    property real size: 28
    signal clicked()
    signal held()
    implicitWidth: Math.max(96 * Ui.s, row.implicitWidth + 40 * Ui.s)
    implicitHeight: 90 * Ui.s
    radius: 10 * Ui.s
    color: !enabled ? "#d9c4a0" : tap.pressed ? Ui.pressed : active ? Ui.accent : Ui.paperDark
    border.color: active ? Ui.woodDark : Ui.wood
    border.width: 4 * Ui.s
    opacity: enabled ? 1 : 0.6
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10 * Ui.s
        Pixel {
            visible: btn.icon !== "" && status === Image.Ready
            sprite: btn.icon
            width: visible ? 48 * Ui.s : 0
            height: 48 * Ui.s
            anchors.verticalCenter: parent.verticalCenter
        }
        Label {
            text: btn.text
            size: btn.size
            bold: true
            color: btn.active ? "white" : Ui.ink
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    TapHandler {
        id: tap
        enabled: btn.enabled
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: btn.clicked()
        onLongPressed: btn.held()
    }
}
