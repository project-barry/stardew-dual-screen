// An item in a line of items: its picture, how many, and its name. Lit when
// it is in your bag.
import QtQuick

Rectangle {
    id: chip
    property string sprite
    property string text
    property int count: 1
    property int quality: 0
    property bool lit: false
    property bool lacking: false     // not enough of it
    property bool showName: true
    implicitWidth: row.implicitWidth + 20 * Ui.s
    implicitHeight: 62 * Ui.s
    radius: 8 * Ui.s
    color: lit ? "#d7efb7" : "#f6d9a0"
    border { color: lit ? Ui.good : Ui.wood; width: 3 * Ui.s }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8 * Ui.s
        Item {
            width: 46 * Ui.s
            height: width
            anchors.verticalCenter: parent.verticalCenter
            visible: chip.sprite !== ""
            Pixel { anchors.fill: parent; sprite: chip.sprite }
            Text {
                visible: chip.quality > 0
                anchors { left: parent.left; bottom: parent.bottom }
                text: "★"
                color: Ui.qualityColors[chip.quality] || Ui.gold
                style: Text.Outline
                styleColor: Ui.woodDark
                font.pixelSize: 20 * Ui.s
            }
        }
        Label {
            visible: chip.showName || chip.count > 1
            text: (chip.count > 1 ? chip.count + "× " : "") + (chip.showName ? chip.text : "")
            size: 24
            color: chip.lacking ? Ui.bad : Ui.ink
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
