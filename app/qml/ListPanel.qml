// A panel with a title and a list that scrolls on its own.
import QtQuick

Panel {
    id: lp
    property string title
    property string note               // right of the title
    property alias model: list.model
    property alias delegate: list.delegate
    property alias header: list.header
    property alias list: list
    property string empty: "Nothing here"
    Label {
        id: heading
        width: parent.width - noteText.width
        text: lp.title
        size: 32
        bold: true
    }
    Label {
        id: noteText
        anchors { right: parent.right; baseline: heading.baseline }
        text: lp.note
        size: 24
        color: Ui.inkSoft
    }
    Rectangle {
        id: rule
        anchors { top: heading.bottom; topMargin: 8 * Ui.s }
        width: parent.width
        height: 3 * Ui.s
        color: Ui.wood
        opacity: 0.5
    }
    ListView {
        id: list
        anchors { top: rule.bottom; topMargin: 8 * Ui.s; left: parent.left; right: parent.right; bottom: parent.bottom }
        clip: true
        spacing: 8 * Ui.s
        boundsBehavior: Flickable.StopAtBounds
        Label {
            anchors.centerIn: parent
            visible: list.count === 0
            text: lp.empty
            color: Ui.inkSoft
            size: 26
        }
    }
}
