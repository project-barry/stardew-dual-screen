// Community Center bundles still to finish, and what each is missing
// (lit: in your bag). The museum at the side.
import QtQuick

Item {
    id: page

    ListPanel {
        id: list
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: parent.width * 0.7
        title: "Community Center"
        note: Ui.game.bundles.length + " bundles to go"
        empty: Ui.game.config && !Ui.game.config.sendBundles ? "Off in Settings" : "Every bundle is done"
        model: Ui.game.bundles
        delegate: Column {
            id: b
            required property var modelData
            required property int index
            // The room's name above its first bundle.
            readonly property bool first: index === 0 || Ui.game.bundles[index - 1].room !== modelData.room
            width: ListView.view.width
            spacing: 4 * Ui.s
            Label {
                visible: b.first
                text: b.modelData.room
                size: 26
                bold: true
                color: Ui.woodDark
                topPadding: b.index > 0 ? 8 * Ui.s : 0
            }
            Rectangle {
                width: parent.width
                height: bc.height + 20 * Ui.s
                radius: 8 * Ui.s
                color: "#f6d9a0"
                border { color: Ui.wood; width: 3 * Ui.s }
                Column {
                    id: bc
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 * Ui.s }
                    spacing: 8 * Ui.s
                    Item {
                        width: parent.width
                        height: bn.height
                        Label { id: bn; text: b.modelData.name + " Bundle"; size: 25; bold: true }
                        Row {
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            spacing: 4 * Ui.s
                            Repeater {
                                model: b.modelData.required
                                Rectangle {
                                    required property int index
                                    width: 22 * Ui.s
                                    height: width
                                    radius: width / 2
                                    color: index < b.modelData.have ? Ui.good : "#e6c38a"
                                    border { color: Ui.wood; width: 2 * Ui.s }
                                }
                            }
                        }
                    }
                    Flow {
                        width: parent.width
                        spacing: 8 * Ui.s
                        Repeater {
                            model: b.modelData.missing
                            Chip {
                                required property var modelData
                                sprite: modelData.id
                                text: modelData.name
                                count: modelData.count
                                quality: modelData.quality
                                lit: modelData.carried
                            }
                        }
                    }
                }
            }
        }
    }

    ListPanel {
        anchors { left: list.right; leftMargin: 10 * Ui.s; right: parent.right; top: parent.top; bottom: parent.bottom }
        title: "Museum"
        note: Ui.game.collections ? Ui.game.collections.donated + "/" + Ui.game.collections.total : ""
        empty: "Nothing in your bag to donate"
        model: Ui.game.collections ? Ui.game.collections.carried : []
        header: Item {
            width: ListView.view.width
            height: Ui.game.collections && Ui.game.collections.carried.length > 0 ? 44 * Ui.s : 0
            Label {
                visible: parent.height > 0
                text: "In your bag, for Gunther:"
                size: 22
                color: Ui.inkSoft
            }
        }
        delegate: Chip {
            required property var modelData
            sprite: modelData.id
            text: modelData.name
            lit: true
        }
    }
}
