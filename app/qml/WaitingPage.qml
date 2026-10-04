// Shown until a save is loaded: what's needed and where the game is looked for.
import QtQuick

Item {
    id: wait
    property string host
    property int port
    signal hostEdited(string host)
    signal closeTapped()

    Panel {
        id: card
        anchors.centerIn: parent
        width: Math.min(parent.width - 80 * Ui.s, 1080 * Ui.s)
        height: Math.min(parent.height - 80 * Ui.s, 900 * Ui.s)
        Column {
            anchors.fill: parent
            anchors.margins: 10 * Ui.s
            spacing: 18 * Ui.s
            Label {
                text: "Stardew Dual Screen"
                size: 52
                bold: true
            }
            Label {
                width: parent.width
                text: Ui.game.status
                size: 30
                color: Ui.game.connected ? Ui.good : Ui.accent
            }
            Rectangle { width: parent.width; height: 3 * Ui.s; color: Ui.wood; opacity: 0.5 }
            Label {
                width: parent.width
                wrapMode: Text.Wrap
                elide: Text.ElideNone
                size: 27
                lineHeight: 1.15
                text: "1.  Install SMAPI in Stardew Valley, and Profmags' Stardew Valley Dual Screen Mod "
                    + "(StardewDualScreenMod.zip from github.com/JoeCorrell/AYN-Thor-Dualscreen-Mods/releases) "
                    + "in its Mods folder.\n"
                    + "2.  Start the game through SMAPI and load your save.\n"
                    + "3.  This screen connects by itself. The game's HUD moves down here while it is connected."
            }
            Label {
                width: parent.width
                wrapMode: Text.Wrap
                elide: Text.ElideNone
                size: 23
                color: Ui.inkSoft
                text: "The mod and its Android companion are by Profmags and JoeCorrell, for WEMU. "
                    + "This Barry Launcher app is Project Barry's separate screen for that mod."
            }
            Row {
                spacing: 14 * Ui.s
                Label {
                    text: "Game at"
                    size: 28
                    anchors.verticalCenter: parent.verticalCenter
                }
                Rectangle {
                    width: 420 * Ui.s
                    height: 90 * Ui.s
                    radius: 8 * Ui.s
                    color: "#fff4d6"
                    border { color: field.activeFocus ? Ui.accent : Ui.wood; width: 4 * Ui.s }
                    TextInput {
                        id: field
                        anchors.fill: parent
                        anchors.margins: 16 * Ui.s
                        verticalAlignment: TextInput.AlignVCenter
                        text: wait.host
                        color: Ui.ink
                        font { family: Ui.font; pixelSize: 30 * Ui.s }
                        inputMethodHints: Qt.ImhUrlCharactersOnly | Qt.ImhNoAutoUppercase
                        onEditingFinished: if (text.trim() !== "") wait.hostEdited(text.trim())
                    }
                }
                Label {
                    text: ":" + wait.port
                    size: 28
                    color: Ui.inkSoft
                    anchors.verticalCenter: parent.verticalCenter
                }
                Button {
                    text: "This device"
                    visible: wait.host !== "127.0.0.1"
                    onClicked: wait.hostEdited("127.0.0.1")
                }
            }
        }
        Button {
            anchors { right: parent.right; bottom: parent.bottom }
            text: "Close"
            onClicked: wait.closeTapped()
        }
        Button {
            anchors { right: parent.right; bottom: parent.bottom; rightMargin: 180 * Ui.s }
            text: "Try now"
            onClicked: Ui.game.reconnect()
        }
    }
}
