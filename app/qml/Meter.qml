// A bar such as energy or health: a letter, the bar, the number.
import QtQuick

Row {
    id: meter
    property string label
    property real value: 0
    property real max: 1
    property color fill: Ui.good
    property real barWidth: 220 * Ui.s
    spacing: 10 * Ui.s
    Label {
        text: meter.label
        size: 24
        bold: true
        color: Ui.ink
        anchors.verticalCenter: parent.verticalCenter
    }
    Rectangle {
        id: bar
        width: meter.barWidth
        height: 34 * Ui.s
        radius: 4 * Ui.s
        color: Ui.woodDark
        anchors.verticalCenter: parent.verticalCenter
        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 4 * Ui.s }
            width: (parent.width - 8 * Ui.s) * Math.max(0, Math.min(1, meter.value / Math.max(1, meter.max)))
            color: meter.value / Math.max(1, meter.max) < 0.25 ? Ui.bad : meter.fill
            radius: 2 * Ui.s
        }
        Text {
            anchors.centerIn: parent
            text: Math.round(meter.value) + "/" + Math.round(meter.max)
            color: "white"
            style: Text.Outline
            styleColor: Ui.woodDark
            font { family: Ui.font; pixelSize: 21 * Ui.s; weight: Font.Bold }
        }
    }
}
