// The top of the screen: date, clock and weather; where you are; gold,
// energy and health; and close. This is the game's HUD, which the mod takes
// off the top screen while this app is connected.
import QtQuick

Panel {
    id: header
    signal closeTapped()
    readonly property var d: Ui.game.day
    pixel: 2.5 * Ui.s

    // Date, then clock and weather.
    Column {
        id: when
        anchors { left: parent.left; leftMargin: 6 * Ui.s; verticalCenter: parent.verticalCenter }
        spacing: 2 * Ui.s
        Row {
            spacing: 10 * Ui.s
            Pixel {
                sprite: "ui:season"
                width: 48 * Ui.s
                height: 32 * Ui.s
                fillMode: Image.Stretch
                anchors.verticalCenter: parent.verticalCenter
                visible: status === Image.Ready
            }
            Label {
                text: header.d ? header.d.weekday.slice(0, 3) + " " + header.d.day + " " + header.d.season
                                 + ", Year " + header.d.year : ""
                size: 30
                bold: true
            }
        }
        Row {
            spacing: 10 * Ui.s
            Pixel {
                sprite: "ui:time"
                width: 48 * Ui.s
                height: 32 * Ui.s
                fillMode: Image.Stretch
                anchors.verticalCenter: parent.verticalCenter
                visible: status === Image.Ready
            }
            Label {
                text: header.d ? Ui.clock(header.d.timeOfDay) + " · " + header.d.weatherToday
                                 + (header.d.weatherTomorrow ? " (" + header.d.weatherTomorrow + " tomorrow)" : "")
                               : ""
                size: 24
                color: Ui.inkSoft
            }
        }
    }

    // Where you are.
    Column {
        anchors { left: when.right; right: purse.left; margins: 14 * Ui.s; verticalCenter: parent.verticalCenter }
        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: header.d ? header.d.location : ""
            size: 26
            bold: true
        }
        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: !header.d ? "" : header.d.playerName ? header.d.playerName + " · " + header.d.farmName + " Farm"
                                                       : Ui.game.saveName + " Farm"
            size: 22
            color: Ui.inkSoft
        }
    }

    // Gold.
    Row {
        id: purse
        anchors { right: meters.left; rightMargin: 18 * Ui.s; verticalCenter: parent.verticalCenter }
        spacing: 8 * Ui.s
        Pixel {
            sprite: "ui:coin"
            width: 40 * Ui.s
            height: 32 * Ui.s
            fillMode: Image.Stretch
            anchors.verticalCenter: parent.verticalCenter
        }
        Label {
            text: header.d ? Ui.number(header.d.gold) + "g" : ""
            size: 32
            bold: true
            color: Ui.woodDark
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Column {
        id: meters
        anchors { right: close.left; rightMargin: 16 * Ui.s; verticalCenter: parent.verticalCenter }
        spacing: 8 * Ui.s
        Meter {
            label: "E"
            barWidth: 190 * Ui.s
            value: header.d ? header.d.energy : 0
            max: header.d ? header.d.maxEnergy : 1
            fill: "#4fbf3a"
        }
        Meter {
            label: "H"
            barWidth: 190 * Ui.s
            value: header.d ? header.d.health : 0
            max: header.d ? header.d.maxHealth : 1
            fill: "#d94b3b"
        }
    }

    Button {
        id: close
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        width: 90 * Ui.s
        text: "✕"
        size: 36
        onClicked: header.closeTapped()
    }
}
