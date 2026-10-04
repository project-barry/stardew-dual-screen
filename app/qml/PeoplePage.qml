// Villagers: friendship, gifts this week, talked today, birthdays. Tap one
// for what they love; items in your bag are lit.
import QtQuick

Item {
    id: page
    property string chosen: ""        // a villager's name
    readonly property var people: Ui.game.villagers.slice().sort((a, b) =>
        (a.birthdayIn === 0 ? -1 : 0) - (b.birthdayIn === 0 ? -1 : 0) || b.hearts - a.hearts || a.name.localeCompare(b.name))
    function lovesOf(name) {
        const g = Ui.game.gifts.find(x => x.name === name)
        return g ? g.loves : []
    }
    readonly property var carrying: Ui.game.gifts.filter(g => g.carrying)

    ListPanel {
        id: list
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: parent.width * 0.56
        title: "Villagers"
        note: Ui.game.villagers.filter(v => !v.talkedToday).length + " not talked to today"
        empty: Ui.game.config && !Ui.game.config.sendVillagers ? "Off in Settings" : "No one met yet"
        model: page.people
        delegate: Rectangle {
            id: v
            required property var modelData
            width: ListView.view.width
            height: 104 * Ui.s
            radius: 8 * Ui.s
            color: tap.pressed ? Ui.pressed : page.chosen === modelData.name ? "#fff1cf" : "#f6d9a0"
            border { color: page.chosen === modelData.name ? Ui.accent : Ui.wood; width: 3 * Ui.s }
            Item {
                id: face
                anchors { left: parent.left; leftMargin: 8 * Ui.s; verticalCenter: parent.verticalCenter }
                width: 84 * Ui.s
                height: width
                Pixel { id: pic; anchors.fill: parent; sprite: "npc:" + v.modelData.npc }
                Rectangle {
                    anchors.fill: parent
                    visible: pic.status !== Image.Ready
                    radius: 8 * Ui.s
                    color: "#e9c27f"
                    Label { anchors.centerIn: parent; text: v.modelData.name.charAt(0); size: 40; bold: true; color: Ui.woodDark }
                }
            }
            Column {
                anchors { left: face.right; leftMargin: 12 * Ui.s; right: parent.right; rightMargin: 10 * Ui.s
                          verticalCenter: parent.verticalCenter }
                spacing: 4 * Ui.s
                Item {
                    width: parent.width
                    height: nameText.height
                    Label { id: nameText; text: v.modelData.name; size: 27; bold: true }
                    Label {
                        anchors { right: parent.right; baseline: nameText.baseline }
                        text: v.modelData.birthdayIn === 0 ? "Birthday today!"
                            : v.modelData.birthdayIn > 0 && v.modelData.birthdayIn <= 7
                              ? "Birthday in " + v.modelData.birthdayIn + (v.modelData.birthdayIn === 1 ? " day" : " days")
                              : v.modelData.birthdaySeason ? v.modelData.birthdaySeason + " " + v.modelData.birthdayDay : ""
                        size: 21
                        color: v.modelData.birthdayIn >= 0 && v.modelData.birthdayIn <= 7 ? Ui.accent : Ui.inkSoft
                        bold: v.modelData.birthdayIn === 0
                    }
                }
                Row {
                    spacing: 12 * Ui.s
                    Hearts {
                        value: v.modelData.hearts
                        max: v.modelData.maxHearts || 10
                        size: (v.modelData.maxHearts > 10 ? 18 : 22) * Ui.s
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Label {
                        text: "gifts " + v.modelData.giftsThisWeek + "/2"
                        size: 20
                        color: v.modelData.giftsThisWeek >= 2 ? Ui.inkSoft : Ui.ink
                    }
                    Label {
                        text: v.modelData.talkedToday ? "talked" : "not talked"
                        size: 20
                        color: v.modelData.talkedToday ? Ui.inkSoft : Ui.accent
                    }
                }
            }
            TapHandler {
                id: tap
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onTapped: page.chosen = page.chosen === v.modelData.name ? "" : v.modelData.name
            }
        }
    }

    // What the chosen villager loves; otherwise, everyone you carry a loved gift for.
    ListPanel {
        anchors { left: list.right; leftMargin: 10 * Ui.s; right: parent.right; top: parent.top; bottom: parent.bottom }
        title: page.chosen ? page.chosen + " loves" : "Loved gifts in your bag"
        empty: page.chosen ? "No loved gifts known" : "None of your items are anyone's favourite"
        model: page.chosen ? [{ name: page.chosen, loves: page.lovesOf(page.chosen) }] : page.carrying
        delegate: Column {
            required property var modelData
            width: ListView.view.width
            spacing: 8 * Ui.s
            Label { visible: !page.chosen; text: modelData.name; size: 26; bold: true }
            Flow {
                width: parent.width
                spacing: 8 * Ui.s
                Repeater {
                    model: page.chosen ? modelData.loves : modelData.loves.filter(l => l.carried)
                    Chip {
                        required property var modelData
                        sprite: modelData.id
                        text: modelData.name
                        lit: modelData.carried
                    }
                }
            }
        }
    }
}
