// Stardew Dual Screen for Barry Launcher: Stardew Valley's companion screen
// on the AYN Thor's bottom screen.
//
// The game side is the Stardew Valley Dual Screen Mod by Profmags
// (https://github.com/JoeCorrell/AYN-Thor-Dualscreen-Mods), a SMAPI mod made
// for WEMU's DualScreen Mods on Android. It serves the game on a local
// WebSocket. This app is a separate client for that socket, written for
// Barry Launcher; it contains none of the mod's or WEMU's code.
import QtQuick
import QtQuick.Layouts
import QtCore
import "qml"

Item {
    id: app
    required property var barry  // from Barry Launcher (AppHost.qml)

    Settings {
        id: saved
        location: app.barry.dataDirUrl + "stardew.ini"
        property string host: "127.0.0.1"
        property int port: 7786
        property int page: 0
        property string ground: ""     // a backdrop tile id, "" = the season's
    }

    Game {
        id: game
        host: saved.host
        port: saved.port
    }

    // The pages need Ui set up first.
    property bool ready: false
    Component.onCompleted: {
        Ui.s = Qt.binding(() => app.barry.scale)
        Ui.game = game
        ready = true
    }

    readonly property var pages: [
        { title: "Bag", icon: "ui:tab_backpack" },
        { title: "Farm", icon: "" },
        { title: "Map", icon: "ui:tab_map" },
        { title: "Journal", icon: "ui:tab_journal" },
        { title: "People", icon: "ui:tab_relationships" },
        { title: "Crafting", icon: "ui:tab_crafting" },
        { title: "Calendar", icon: "" },
        { title: "Bundles", icon: "" },
        { title: "Settings", icon: "ui:tab_settings" }
    ]
    readonly property int settingsPage: 8
    // For tests: show a page; the game.
    function show(i) { saved.page = i }
    function testGame() { return game }

    Loader {
        anchors.fill: parent
        active: app.ready
        sourceComponent: Item {
            Backdrop {
                anchors.fill: parent
                tile: saved.ground
            }

            Header {
                id: header
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 * Ui.s }
                height: 128 * Ui.s
                visible: game.inGame
                onCloseTapped: app.barry.close()
            }

            Tabs {
                id: tabs
                anchors { left: parent.left; right: parent.right; top: header.bottom; margins: 14 * Ui.s; topMargin: 10 * Ui.s }
                height: 96 * Ui.s
                visible: game.inGame
                pages: app.pages
                current: saved.page
                onPicked: i => saved.page = i
            }

            StackLayout {
                anchors { left: parent.left; right: parent.right; top: tabs.bottom; bottom: parent.bottom
                          margins: 14 * Ui.s; topMargin: 10 * Ui.s }
                visible: game.inGame
                currentIndex: saved.page
                BackpackPage {}
                FarmPage {}
                MapPage {}
                JournalPage {}
                PeoplePage {}
                CraftingPage {}
                CalendarPage {}
                BundlesPage {}
                SettingsPage {
                    host: saved.host
                    port: saved.port
                    ground: saved.ground
                    onHostEdited: h => saved.host = h
                    onPortEdited: p => saved.port = p
                    onGroundPicked: g => saved.ground = g
                }
            }

            // No save loaded yet: how to get the game talking, and where it is
            // looked for (another computer's address can be typed here).
            WaitingPage {
                anchors.fill: parent
                visible: !game.inGame
                host: saved.host
                port: saved.port
                onHostEdited: h => saved.host = h
                onCloseTapped: app.barry.close()
            }
        }
    }
}
