// Friendship hearts, with the game's heart pictures.
import QtQuick

Row {
    id: hearts
    property int value: 0
    property int max: 10
    property real size: 26 * Ui.s
    spacing: 2 * Ui.s
    Repeater {
        model: hearts.max
        Item {
            required property int index
            width: hearts.size
            height: hearts.size * 6 / 7
            Pixel {
                id: pic
                anchors.fill: parent
                fillMode: Image.Stretch
                sprite: parent.index < hearts.value ? "ui:heart" : "ui:heart_empty"
            }
            Text {
                visible: pic.status !== Image.Ready
                anchors.centerIn: parent
                text: "♥"
                color: parent.index < hearts.value ? Ui.bad : "#b49a80"
                font.pixelSize: hearts.size
            }
        }
    }
}
