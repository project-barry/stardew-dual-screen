// The mod's options (they are saved in its config.json), the backdrop,
// where the game is, and credits.
import QtQuick

Item {
    id: page
    property string host
    property int port
    property string ground
    signal hostEdited(string host)
    signal portEdited(int port)
    signal groundPicked(string ground)
    readonly property var cfg: Ui.game.config

    readonly property var options: [
        ["hideGameHud", "Hide the game's HUD", "Take the clock, gold and bars off the top screen while this is connected"],
        ["allowInventoryEdits", "Inventory edits", "Select, move, eat, sort and craft from here"],
        ["allowQuestCancel", "Cancel quests", "Allow cancelling quests the game lets you cancel"],
        ["farmerMarker", "Farmer on the map", "Your farmer's face as the map marker"],
        ["sendMap", "Map", "The valley map and where you are"],
        ["sendCrops", "Crops and fruit trees", ""],
        ["sendMachines", "Machines", ""],
        ["sendAnimals", "Animals", ""],
        ["sendBundles", "Bundles", ""],
        ["sendVillagers", "Villagers and gifts", ""],
        ["sendCrafting", "Crafting and cooking", "Checks every recipe against your bag"]
    ]

    ListPanel {
        id: opts
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: parent.width * 0.5
        title: "Mod options"
        note: "saved in the game's mod"
        model: page.cfg ? page.options : []
        empty: "Waiting for the game"
        delegate: Toggle {
            required property var modelData
            width: ListView.view.width
            text: modelData[1]
            detail: modelData[2]
            checked: page.cfg ? !!page.cfg[modelData[0]] : false
            onToggled: on => Ui.game.setOption(modelData[0], on)
        }
    }

    Flickable {
        anchors { left: opts.right; leftMargin: 10 * Ui.s; right: parent.right; top: parent.top; bottom: parent.bottom }
        contentHeight: side.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Column {
            id: side
            width: parent.width
            spacing: 10 * Ui.s

            Panel {
                width: parent.width
                height: grounds.height + 2 * padding
                Column {
                    id: grounds
                    width: parent.width
                    spacing: 8 * Ui.s
                    Label { text: "Backdrop"; size: 28; bold: true }
                    Flow {
                        width: parent.width
                        spacing: 8 * Ui.s
                        Repeater {
                            model: [""].concat(Ui.game.grounds)
                            Rectangle {
                                required property string modelData
                                width: 72 * Ui.s
                                height: width
                                color: "#4f7f35"
                                border { color: page.ground === modelData ? Ui.bad : Ui.wood
                                         width: (page.ground === modelData ? 6 : 3) * Ui.s }
                                Pixel {
                                    anchors.fill: parent
                                    anchors.margins: 6 * Ui.s
                                    fillMode: Image.Stretch
                                    sprite: modelData || "ui:ground"
                                }
                                Label {
                                    visible: modelData === ""
                                    anchors.centerIn: parent
                                    text: "Season"
                                    size: 16
                                    color: "white"
                                    style: Text.Outline
                                    styleColor: "black"
                                }
                                TapHandler { onTapped: page.groundPicked(modelData) }
                            }
                        }
                    }
                }
            }

            Panel {
                width: parent.width
                height: conn.height + 2 * padding
                Column {
                    id: conn
                    width: parent.width
                    spacing: 8 * Ui.s
                    Label { text: "Connection"; size: 28; bold: true }
                    Label {
                        width: parent.width
                        text: Ui.game.status + " · " + page.host + ":" + page.port
                        size: 22
                        color: Ui.game.connected ? Ui.good : Ui.accent
                    }
                    Row {
                        spacing: 10 * Ui.s
                        Rectangle {
                            width: 300 * Ui.s
                            height: 90 * Ui.s
                            radius: 8 * Ui.s
                            color: "#fff4d6"
                            border { color: hostField.activeFocus ? Ui.accent : Ui.wood; width: 4 * Ui.s }
                            TextInput {
                                id: hostField
                                anchors.fill: parent
                                anchors.margins: 14 * Ui.s
                                verticalAlignment: TextInput.AlignVCenter
                                text: page.host
                                color: Ui.ink
                                font { family: Ui.font; pixelSize: 28 * Ui.s }
                                inputMethodHints: Qt.ImhUrlCharactersOnly | Qt.ImhNoAutoUppercase
                                onEditingFinished: if (text.trim() !== "") page.hostEdited(text.trim())
                            }
                        }
                        Button { text: "Reconnect"; onClicked: Ui.game.reconnect() }
                    }
                    Label {
                        width: parent.width
                        wrapMode: Text.Wrap
                        elide: Text.ElideNone
                        size: 20
                        color: Ui.inkSoft
                        text: "127.0.0.1 is this device. For a game on another computer, that computer's mod "
                            + "needs \"AllowRemote\": true in its config.json."
                    }
                    Button { text: "Send everything again"; onClicked: Ui.game.refresh() }
                }
            }

            Panel {
                width: parent.width
                height: credits.height + 2 * padding
                Column {
                    id: credits
                    width: parent.width
                    spacing: 6 * Ui.s
                    Label { text: "Credits"; size: 28; bold: true }
                    Label {
                        width: parent.width
                        wrapMode: Text.Wrap
                        elide: Text.ElideNone
                        size: 21
                        text: "The game side is the Stardew Valley Dual Screen Mod by Profmags, from JoeCorrell's "
                            + "AYN Thor DualScreen Mods for WEMU:\ngithub.com/JoeCorrell/AYN-Thor-Dualscreen-Mods\n\n"
                            + "Everything this screen shows, the mod reads from your game, and the pictures are the "
                            + "game's own art, which it sends. This app is Project Barry's client for that mod on "
                            + "Barry Launcher. It is not by or endorsed by them, and it contains none of their code.\n\n"
                            + "Stardew Valley is by ConcernedApe."
                    }
                }
            }
        }
    }
}
