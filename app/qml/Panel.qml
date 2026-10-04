// A framed menu panel: the game's own (ui:panel), scaled up as pixel art,
// or a drawn one until that arrives.
import QtQuick

Item {
    id: panel
    property real pixel: 3 * Ui.s       // screen pixels per picture pixel
    property string art: "ui:panel"
    readonly property bool hasArt: Ui.game && Ui.game.hasSprite(art)
    readonly property real padding: hasArt ? Math.max(14 * Ui.s, Ui.game.inset(art) * pixel * 0.55) : 16 * Ui.s
    default property alias content: inner.data

    Rectangle {
        anchors.fill: parent
        visible: !panel.hasArt
        color: Ui.paper
        radius: 10 * Ui.s
        border.color: Ui.wood
        border.width: 6 * Ui.s
    }
    BorderImage {
        visible: panel.hasArt
        width: parent.width / panel.pixel
        height: parent.height / panel.pixel
        scale: panel.pixel
        transformOrigin: Item.TopLeft
        smooth: false
        source: panel.hasArt ? Ui.game.sprite(panel.art) : ""
        readonly property int b: Ui.game ? Ui.game.inset(panel.art) : 0
        border { left: b; right: b; top: b; bottom: b }
        horizontalTileMode: BorderImage.Stretch
        verticalTileMode: BorderImage.Stretch
    }
    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: panel.padding
    }
}
