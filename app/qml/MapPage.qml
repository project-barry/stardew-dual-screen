// The valley map with you on it, and villagers where the 2.0 mod says
// they are. Drag to move, pinch or use the buttons to zoom.
import QtQuick

Item {
    id: page
    readonly property var d: Ui.game.day
    readonly property bool here: d && d.mapX >= 0 && d.mapY >= 0
    readonly property var placed: Ui.game.villagers.filter(v => v.mapX !== undefined && v.mapX >= 0 && v.mapY >= 0)
    property real zoom: 1

    Panel {
        id: frame
        anchors { left: parent.left; right: parent.right; top: parent.top; bottom: strip.top; bottomMargin: 10 * Ui.s }
        Flickable {
            id: flick
            anchors.fill: parent
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            // The picture fits the panel at zoom 1.
            readonly property real fit: map.sourceSize.width > 0
                ? Math.min(width / map.sourceSize.width, height / map.sourceSize.height) : 1
            contentWidth: Math.max(width, map.sourceSize.width * fit * page.zoom)
            contentHeight: Math.max(height, map.sourceSize.height * fit * page.zoom)
            Item {
                id: world
                width: map.sourceSize.width * flick.fit * page.zoom
                height: map.sourceSize.height * flick.fit * page.zoom
                x: Math.max(0, (flick.contentWidth - width) / 2)
                y: Math.max(0, (flick.contentHeight - height) / 2)
                Pixel {
                    id: map
                    anchors.fill: parent
                    fillMode: Image.Stretch
                    sprite: "ui:map"
                }
                Repeater {
                    model: page.placed
                    Item {
                        required property var modelData
                        x: modelData.mapX / 1000 * world.width - width / 2
                        y: modelData.mapY / 1000 * world.height - height / 2
                        width: 52 * Ui.s
                        height: width
                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: Ui.paper
                            border { color: Ui.wood; width: 3 * Ui.s }
                        }
                        Pixel {
                            id: face
                            anchors.fill: parent
                            anchors.margins: 4 * Ui.s
                            sprite: "npc:" + modelData.npc
                        }
                        Label {
                            anchors.centerIn: parent
                            visible: face.status !== Image.Ready
                            text: modelData.name.charAt(0)
                            size: 24
                            bold: true
                        }
                    }
                }
                // You: your farmer's face, or a red dot.
                Item {
                    visible: page.here
                    x: page.here ? page.d.mapX / 1000 * world.width - width / 2 : 0
                    y: page.here ? page.d.mapY / 1000 * world.height - height / 2 : 0
                    width: 76 * Ui.s
                    height: width
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width * 0.5
                        height: width
                        radius: width / 2
                        color: Ui.bad
                        border { color: "white"; width: 4 * Ui.s }
                        visible: you.status !== Image.Ready
                    }
                    Pixel {
                        id: you
                        anchors.fill: parent
                        sprite: Ui.game.config && !Ui.game.config.farmerMarker ? "" : "ui:player"
                    }
                }
            }
            PinchHandler {
                target: null
                property real start: 1
                onActiveChanged: if (active) start = page.zoom
                onActiveScaleChanged: page.zoom = Math.max(1, Math.min(5, start * activeScale))
            }
        }
        Label {
            anchors.centerIn: parent
            visible: map.status !== Image.Ready
            text: Ui.game.config && !Ui.game.config.sendMap ? "The map is off in Settings" : "Waiting for the map…"
            size: 30
            color: Ui.inkSoft
        }
        Column {
            anchors { right: parent.right; top: parent.top }
            spacing: 10 * Ui.s
            Button { text: "+"; size: 40; onClicked: page.zoom = Math.min(5, page.zoom * 1.5) }
            Button { text: "−"; size: 40; onClicked: page.zoom = Math.max(1, page.zoom / 1.5) }
            Button {
                text: "◎"
                size: 36
                enabled: page.here
                onClicked: page.centreOn(page.d.mapX, page.d.mapY)
            }
        }
        Panel {
            anchors { left: parent.left; bottom: parent.bottom }
            width: placeLabel.implicitWidth + 2 * padding
            height: 70 * Ui.s
            pixel: 2 * Ui.s
            Label {
                id: placeLabel
                anchors.verticalCenter: parent.verticalCenter
                text: page.d ? page.d.location + (page.here ? "" : " (not on the valley map)") : ""
                size: 26
                bold: true
            }
        }
    }

    function centreOn(mx, my) {
        flick.contentX = Math.max(0, Math.min(flick.contentWidth - flick.width, world.x + mx / 1000 * world.width - flick.width / 2))
        flick.contentY = Math.max(0, Math.min(flick.contentHeight - flick.height, world.y + my / 1000 * world.height - flick.height / 2))
    }

    // Who is where (2.0 mod). Tap one to find them on the map.
    Panel {
        id: strip
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: page.placed.length > 0 ? 130 * Ui.s : 0
        visible: height > 0
        pixel: 2 * Ui.s
        ListView {
            anchors.fill: parent
            orientation: ListView.Horizontal
            spacing: 10 * Ui.s
            clip: true
            model: page.placed
            delegate: Rectangle {
                required property var modelData
                width: 270 * Ui.s
                height: ListView.view.height
                radius: 8 * Ui.s
                color: tap.pressed ? Ui.pressed : "#f6d9a0"
                border { color: Ui.wood; width: 3 * Ui.s }
                Pixel {
                    id: pic
                    anchors { left: parent.left; leftMargin: 6 * Ui.s; verticalCenter: parent.verticalCenter }
                    width: 60 * Ui.s
                    height: width
                    sprite: "npc:" + modelData.npc
                }
                Column {
                    anchors { left: pic.right; leftMargin: 8 * Ui.s; right: parent.right; rightMargin: 6 * Ui.s
                              verticalCenter: parent.verticalCenter }
                    Label { width: parent.width; text: modelData.name; size: 24; bold: true }
                    Label { width: parent.width; text: modelData.location || ""; size: 19; color: Ui.inkSoft }
                }
                TapHandler {
                    id: tap
                    onTapped: {
                        page.zoom = Math.max(page.zoom, 2.5)
                        Qt.callLater(page.centreOn, modelData.mapX, modelData.mapY)
                    }
                }
            }
        }
    }
}
