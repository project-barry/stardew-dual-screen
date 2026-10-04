// The season: four weeks, with birthdays, festivals and the travelling
// cart (in the forest every Friday and Sunday).
import QtQuick

Item {
    id: page
    readonly property var cal: Ui.game.calendar
    readonly property var byDay: {
        const m = {}
        if (cal)
            for (const d of cal.days) m[d.day] = d
        return m
    }
    readonly property var events: cal ? cal.days : []

    Panel {
        id: grid
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: parent.width * 0.66
        Label {
            id: title
            text: page.cal ? page.cal.season : ""
            size: 34
            bold: true
        }
        Row {
            id: weekdays
            anchors { top: title.bottom; topMargin: 4 * Ui.s }
            Repeater {
                model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                Label {
                    required property string modelData
                    width: grid.width / 7 - 2 * grid.padding / 7
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    size: 22
                    color: Ui.inkSoft
                }
            }
        }
        Grid {
            id: days
            anchors { top: weekdays.bottom; topMargin: 4 * Ui.s; left: parent.left; right: parent.right; bottom: parent.bottom }
            columns: 7
            readonly property real cw: width / 7
            readonly property real ch: height / 4
            Repeater {
                model: 28
                Rectangle {
                    id: cell
                    required property int index
                    readonly property int day: index + 1
                    readonly property var ev: page.byDay[day]
                    readonly property bool today: page.cal && page.cal.today === day
                    readonly property bool cart: index % 7 === 4 || index % 7 === 6
                    width: days.cw
                    height: days.ch
                    color: today ? "#ffe9a8" : ev && ev.festival ? "#f3d7f0" : "#f8deaa"
                    border { color: today ? Ui.bad : Ui.wood; width: (today ? 5 : 2) * Ui.s }
                    opacity: page.cal && day < page.cal.today ? 0.6 : 1
                    Label {
                        anchors { left: parent.left; top: parent.top; margins: 6 * Ui.s }
                        text: cell.day
                        size: 24
                        bold: true
                    }
                    Text {
                        visible: cell.cart
                        anchors { right: parent.right; top: parent.top; margins: 6 * Ui.s }
                        text: "🛒"
                        font.pixelSize: 20 * Ui.s
                        opacity: 0.6
                    }
                    Pixel {
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 4 * Ui.s }
                        width: Math.min(parent.width, parent.height) * 0.62
                        height: width
                        sprite: cell.ev && cell.ev.npc ? "npc:" + cell.ev.npc : ""
                    }
                    Label {
                        visible: !!(cell.ev && cell.ev.festival)
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 4 * Ui.s }
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        text: cell.ev ? cell.ev.festival : ""
                        size: 18
                        color: "#7a2a8c"
                        bold: true
                    }
                }
            }
        }
    }

    ListPanel {
        anchors { left: grid.right; leftMargin: 10 * Ui.s; right: parent.right; top: parent.top; bottom: parent.bottom }
        title: "This season"
        empty: "Nothing on"
        model: page.events
        delegate: Column {
            required property var modelData
            width: ListView.view.width
            spacing: 2 * Ui.s
            readonly property bool past: page.cal && modelData.day < page.cal.today
            opacity: past ? 0.55 : 1
            Label {
                width: parent.width
                text: page.cal.season + " " + modelData.day + (page.cal.today === modelData.day ? " (today)" : "")
                size: 22
                color: Ui.inkSoft
            }
            Label {
                width: parent.width
                visible: modelData.festival !== ""
                text: modelData.festival
                size: 25
                bold: true
                color: "#7a2a8c"
            }
            Label {
                width: parent.width
                visible: modelData.festival !== "" && (modelData.festivalWhen || modelData.festivalWhere)
                text: [modelData.festivalWhen, modelData.festivalWhere].filter(x => x).join(" · ")
                size: 21
                color: Ui.inkSoft
            }
            Label {
                width: parent.width
                visible: modelData.names !== ""
                text: modelData.names + "'s birthday"
                size: 25
                bold: true
            }
        }
    }
}
