import QtQuick

Text {
    property real size: 28
    property bool bold: false
    color: Ui.ink
    font { family: Ui.font; pixelSize: size * Ui.s; weight: bold ? Font.Bold : Font.DemiBold }
    elide: Text.ElideRight
    textFormat: Text.PlainText
}
