// Quests (tap one for its details; cancel where the game allows) and
// special orders.
import QtQuick

Item {
    id: page
    property int open: -1             // the quest index shown in full
    property int confirm: -1          // asking before cancelling this one
    readonly property bool canCancel: !Ui.game.config || Ui.game.config.allowQuestCancel

    ListPanel {
        id: quests
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: parent.width * 0.62
        title: "Quests"
        note: Ui.game.quests.length + " active"
        empty: "No quests"
        model: Ui.game.quests
        delegate: Rectangle {
            id: q
            required property var modelData
            readonly property bool expanded: page.open === modelData.index
            width: ListView.view.width
            height: col.height + 24 * Ui.s
            radius: 8 * Ui.s
            color: tap.pressed ? Ui.pressed : expanded ? "#fff1cf" : "#f6d9a0"
            border { color: modelData.complete ? Ui.good : Ui.wood; width: 3 * Ui.s }
            Column {
                id: col
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 * Ui.s }
                spacing: 6 * Ui.s
                Label {
                    width: parent.width
                    text: (q.modelData.complete ? "✓ " : "") + q.modelData.title
                    size: 27
                    bold: true
                }
                Label {
                    width: parent.width
                    text: q.modelData.objective
                    size: 23
                    wrapMode: Text.Wrap
                    elide: Text.ElideNone
                    color: Ui.inkSoft
                    visible: text !== ""
                }
                Row {
                    spacing: 18 * Ui.s
                    Label {
                        visible: q.modelData.daysLeft > 0
                        text: q.modelData.daysLeft + (q.modelData.daysLeft === 1 ? " day left" : " days left")
                        size: 22
                        color: q.modelData.daysLeft <= 1 ? Ui.bad : Ui.ink
                    }
                    Label {
                        visible: q.modelData.reward > 0
                        text: "Reward " + Ui.number(q.modelData.reward) + "g"
                        size: 22
                        color: Ui.woodDark
                    }
                    Label { visible: q.modelData.daily; text: "Help wanted"; size: 22; color: Ui.inkSoft }
                }
                Label {
                    width: parent.width
                    visible: q.expanded && text !== ""
                    text: q.modelData.detail
                    size: 23
                    wrapMode: Text.Wrap
                    elide: Text.ElideNone
                }
                Row {
                    visible: q.expanded && q.modelData.cancellable && page.canCancel
                    spacing: 12 * Ui.s
                    Button {
                        text: page.confirm === q.modelData.index ? "Yes, cancel it" : "Cancel quest"
                        active: page.confirm === q.modelData.index
                        onClicked: {
                            if (page.confirm === q.modelData.index) {
                                Ui.game.cancelQuest(q.modelData.index)
                                page.confirm = -1
                                page.open = -1
                            } else {
                                page.confirm = q.modelData.index
                            }
                        }
                    }
                    Button {
                        visible: page.confirm === q.modelData.index
                        text: "Keep it"
                        onClicked: page.confirm = -1
                    }
                }
            }
            TapHandler {
                id: tap
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onTapped: {
                    page.confirm = -1
                    page.open = q.expanded ? -1 : q.modelData.index
                }
            }
        }
    }

    ListPanel {
        anchors { left: quests.right; leftMargin: 10 * Ui.s; right: parent.right; top: parent.top; bottom: parent.bottom }
        title: "Special orders"
        empty: "None taken"
        model: Ui.game.orders
        delegate: Rectangle {
            required property var modelData
            width: ListView.view.width
            height: oc.height + 24 * Ui.s
            radius: 8 * Ui.s
            color: "#f6d9a0"
            border { color: Ui.wood; width: 3 * Ui.s }
            Column {
                id: oc
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 * Ui.s }
                spacing: 6 * Ui.s
                Label { width: parent.width; text: modelData.title; size: 26; bold: true }
                Label {
                    width: parent.width
                    text: modelData.objective
                    size: 22
                    wrapMode: Text.Wrap
                    elide: Text.ElideNone
                    color: Ui.inkSoft
                }
                Label {
                    text: modelData.daysLeft + (modelData.daysLeft === 1 ? " day left" : " days left")
                    size: 22
                    color: modelData.daysLeft <= 1 ? Ui.bad : Ui.ink
                }
            }
        }
    }
}
