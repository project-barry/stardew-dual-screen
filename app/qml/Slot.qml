// One inventory slot: the game's slot art, the item, its stack, quality,
// a watering can's water and a weapon's cooldown.
import QtQuick

Item {
    id: slot
    property var item: null          // {id, name, count, quality, water, waterMax, cooldownMs, cooldownMax}
    property bool selected: false
    property bool locked: false
    property real pixel: width / 64   // the slot picture is 64 x 64
    readonly property bool empty: !item || !item.id
    signal tapped()
    signal held()

    Rectangle {
        anchors.fill: parent
        visible: !art.visible
        color: slot.locked ? "#c9a46a" : "#f4cf8c"
        border.color: slot.selected ? Ui.bad : Ui.wood
        border.width: (slot.selected ? 6 : 3) * Ui.s
        radius: 4 * Ui.s
    }
    Pixel {
        id: art
        anchors.fill: parent
        fillMode: Image.Stretch
        sprite: slot.selected ? "ui:slot_selected" : "ui:slot"
        visible: status === Image.Ready && !slot.locked
    }
    Rectangle {
        anchors.fill: parent
        visible: slot.locked
        color: "#80000000"
        radius: 4 * Ui.s
    }
    Pixel {
        id: picture
        anchors.centerIn: parent
        width: parent.width * 0.75
        height: width
        sprite: slot.empty ? "" : slot.item.id
        visible: !slot.empty
    }
    // Until the game sends the picture: the name's first letters.
    Label {
        anchors.centerIn: parent
        width: parent.width - 8 * Ui.s
        horizontalAlignment: Text.AlignHCenter
        visible: !slot.empty && picture.status !== Image.Ready
        text: slot.empty ? "" : (slot.item.name || "?").slice(0, 4)
        size: 20
    }
    // Quality: silver, gold, iridium.
    Text {
        visible: !slot.empty && slot.item.quality > 0
        anchors { left: parent.left; bottom: parent.bottom; margins: 4 * Ui.s }
        text: "★"
        color: slot.empty ? "transparent" : Ui.qualityColors[slot.item.quality] || Ui.gold
        style: Text.Outline
        styleColor: Ui.woodDark
        font.pixelSize: parent.height * 0.3
    }
    Text {
        visible: !slot.empty && slot.item.count > 1
        anchors { right: parent.right; bottom: parent.bottom; rightMargin: 5 * Ui.s; bottomMargin: 1 * Ui.s }
        text: slot.empty ? "" : slot.item.count
        color: "white"
        style: Text.Outline
        styleColor: Ui.woodDark
        font { family: Ui.font; pixelSize: parent.height * 0.27; weight: Font.Black }
    }
    // Water left in a watering can.
    Rectangle {
        readonly property bool can: !slot.empty && slot.item.waterMax > 0
        visible: can
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: parent.width * 0.12 }
        height: parent.height * 0.09
        color: Ui.woodDark
        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 2 * Ui.s }
            width: parent.can ? (parent.width - 4 * Ui.s) * (slot.item.bottomless ? 1
                    : Math.max(0, slot.item.water) / slot.item.waterMax) : 0
            color: Ui.water
        }
    }
    // A weapon's special move cooling down.
    Rectangle {
        readonly property bool cooling: !slot.empty && slot.item.cooldownMs > 0 && slot.item.cooldownMax > 0
        visible: cooling
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: cooling ? parent.height * Math.min(1, slot.item.cooldownMs / slot.item.cooldownMax) : 0
        color: "#99b83224"
    }
    TapHandler {
        enabled: !slot.locked
        gesturePolicy: TapHandler.ReleaseWithinBounds
        longPressThreshold: 0.6
        onTapped: slot.tapped()
        onLongPressed: slot.held()
    }
}
