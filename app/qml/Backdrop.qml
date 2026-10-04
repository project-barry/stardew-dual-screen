// The ground behind everything: a tile from the game (the season's grass,
// or the one picked in Settings), repeated; plain grass until it arrives.
import QtQuick

Item {
    id: back
    property string tile: "ui:ground"
    property real pixel: 4 * Ui.s
    clip: true
    Rectangle {
        anchors.fill: parent
        color: "#4f7f35"
    }
    Image {
        width: parent.width / back.pixel + 1
        height: parent.height / back.pixel + 1
        scale: back.pixel
        transformOrigin: Item.TopLeft
        smooth: false
        fillMode: Image.Tile
        source: Ui.game ? Ui.game.sprite(back.tile) || Ui.game.sprite("ui:ground") : ""
    }
    // Darker, so the panels stand out.
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.22
    }
}
