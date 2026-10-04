// A setting that is on or off, with the game's check boxes.
import QtQuick

Item {
    id: toggle
    property string text
    property string detail
    property bool checked
    signal toggled(bool on)
    implicitHeight: Math.max(96 * Ui.s, words.implicitHeight + 24 * Ui.s)
    Rectangle {
        anchors.fill: parent
        color: tap.pressed ? Ui.pressed : "transparent"
        radius: 8 * Ui.s
    }
    Item {
        id: box
        width: 54 * Ui.s
        height: width
        anchors { left: parent.left; leftMargin: 10 * Ui.s; verticalCenter: parent.verticalCenter }
        Pixel {
            id: pic
            anchors.fill: parent
            fillMode: Image.Stretch
            sprite: toggle.checked ? "ui:check_on" : "ui:check_off"
        }
        Rectangle {
            visible: pic.status !== Image.Ready
            anchors.fill: parent
            color: "#fff4d6"
            border { color: Ui.wood; width: 4 * Ui.s }
            Text {
                anchors.centerIn: parent
                visible: toggle.checked
                text: "✓"
                color: Ui.good
                font { pixelSize: parent.height * 0.8; weight: Font.Black }
            }
        }
    }
    Column {
        id: words
        anchors { left: box.right; leftMargin: 20 * Ui.s; right: parent.right; verticalCenter: parent.verticalCenter }
        Label { width: parent.width; text: toggle.text; size: 28; bold: true }
        Label {
            width: parent.width
            visible: toggle.detail !== ""
            text: toggle.detail
            size: 22
            color: Ui.inkSoft
            wrapMode: Text.Wrap
            elide: Text.ElideNone
        }
    }
    TapHandler {
        id: tap
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: toggle.toggled(!toggle.checked)
    }
}
