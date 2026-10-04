// The hotbar and the backpack, then skills and the day's odds and ends.
// Tap a hotbar slot to hold it; tap a backpack item to swap it into the
// slot you hold; hold an item to eat or use it.
import QtQuick

Item {
    id: page
    readonly property var inv: Ui.game.inventory
    readonly property var items: inv ? inv.items : []
    readonly property int capacity: inv ? inv.capacity : 12
    readonly property int selected: inv ? inv.selected : 0
    readonly property var held: selected >= 0 && selected < items.length ? items[selected] : null
    readonly property bool editable: !Ui.game.config || Ui.game.config.allowInventoryEdits
    readonly property real gap: 8 * Ui.s

    Panel {
        id: bag
        anchors { left: parent.left; right: parent.right; top: parent.top }
        readonly property real cell: Math.min((width - 2 * padding - 11 * page.gap) / 12, 92 * Ui.s)
        height: 2 * padding + 3 * cell + 2 * page.gap + 14 * Ui.s
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: page.gap
            Repeater {
                model: 3
                Row {
                    id: row
                    required property int index
                    spacing: page.gap
                    // A line under the hotbar.
                    topPadding: index === 1 ? 14 * Ui.s : 0
                    Repeater {
                        model: 12
                        Slot {
                            required property int index
                            readonly property int at: row.index * 12 + index
                            width: bag.cell
                            height: bag.cell
                            item: at < page.items.length ? page.items[at] : null
                            selected: at === page.selected
                            locked: at >= page.capacity
                            onTapped: {
                                if (!page.editable) return
                                if (at < 12) Ui.game.selectSlot(at)
                                else if (!empty) Ui.game.moveItem(at, page.selected)
                            }
                            onHeld: if (page.editable && !empty) Ui.game.eatSlot(at)
                        }
                    }
                }
            }
        }
    }

    // What you hold, and the bag's buttons.
    Item {
        id: bar
        anchors { left: parent.left; right: parent.right; top: bag.bottom; topMargin: 10 * Ui.s }
        height: 90 * Ui.s
        Panel {
            anchors { left: parent.left; right: buttons.left; rightMargin: 10 * Ui.s; top: parent.top; bottom: parent.bottom }
            pixel: 2 * Ui.s
            Label {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                size: 26
                text: !page.editable ? "The mod's \"Inventory edits\" option is off (Settings)."
                    : page.held && page.held.id
                      ? page.held.name + (page.held.category ? "  ·  " + page.held.category : "")
                        + (page.held.waterMax > 0 ? "  ·  " + (page.held.bottomless ? "bottomless"
                           : page.held.water + "/" + page.held.waterMax + " water") : "")
                      : "Tap: hold it, or swap it in. Hold: eat or use it."
            }
        }
        Row {
            id: buttons
            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
            spacing: 10 * Ui.s
            Button {
                height: parent.height
                text: "◀ Rows"
                enabled: page.editable && page.capacity > 12
                onClicked: Ui.game.shiftToolbar(false)
            }
            Button {
                height: parent.height
                text: "Rows ▶"
                enabled: page.editable && page.capacity > 12
                onClicked: Ui.game.shiftToolbar(true)
            }
            Button {
                height: parent.height
                text: "Sort"
                icon: "ui:sort"
                enabled: page.editable
                onClicked: Ui.game.sortBag()
            }
        }
    }

    Panel {
        id: skills
        anchors { left: parent.left; top: bar.bottom; bottom: parent.bottom; topMargin: 10 * Ui.s }
        width: parent.width * 0.47
        readonly property var sk: Ui.game.skills
        Column {
            anchors.fill: parent
            Label { id: skillsTitle; text: "Skills"; size: 30; bold: true }
            Repeater {
                model: ["farming", "mining", "foraging", "fishing", "combat"]
                Item {
                    required property string modelData
                    readonly property int level: skills.sk ? skills.sk[modelData] || 0 : 0
                    readonly property int next: skills.sk ? skills.sk[modelData + "Next"] : -1
                    width: parent.width
                    height: (parent.height - skillsTitle.height) / 5
                    Label {
                        id: name
                        width: 136 * Ui.s
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                        size: 26
                    }
                    Row {
                        id: pips
                        anchors { left: name.right; verticalCenter: parent.verticalCenter }
                        spacing: 3 * Ui.s
                        Repeater {
                            model: 10
                            Rectangle {
                                required property int index
                                width: 15 * Ui.s
                                height: 26 * Ui.s
                                radius: 3 * Ui.s
                                color: index < level ? Ui.accent : "#e6c38a"
                                border { color: Ui.wood; width: 2 * Ui.s }
                            }
                        }
                    }
                    Label {
                        anchors { left: pips.right; leftMargin: 12 * Ui.s; right: parent.right; verticalCenter: parent.verticalCenter }
                        text: level >= 10 ? "Lv 10" : "Lv " + level + (next > 0 ? " · " + Ui.number(next) + " xp" : "")
                        size: 22
                        color: Ui.inkSoft
                    }
                }
            }
        }
    }

    Panel {
        anchors { left: skills.right; leftMargin: 10 * Ui.s; right: parent.right; top: bar.bottom; bottom: parent.bottom; topMargin: 10 * Ui.s }
        readonly property var g: Ui.game
        Flickable {
            anchors.fill: parent
            contentHeight: today.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: today
                width: parent.width
                spacing: 6 * Ui.s
                Label { text: "Today"; size: 30; bold: true }
                Label {
                    width: parent.width
                    text: Ui.luck(Ui.game.day ? Ui.game.day.luck : undefined)
                    color: Ui.luckColor(Ui.game.day ? Ui.game.day.luck : 0)
                    size: 24
                }
                Label {
                    width: parent.width
                    size: 24
                    text: Ui.game.shipping ? "Shipping bin: " + Ui.number(Ui.game.shipping.total) + "g ("
                        + Ui.game.shipping.items.length + " kinds)" : ""
                    visible: text !== ""
                }
                Label {
                    width: parent.width
                    size: 24
                    text: Ui.game.cartOpen ? "The travelling cart is in the forest" : "No travelling cart today"
                    color: Ui.game.cartOpen ? Ui.good : Ui.ink
                }
                Label {
                    width: parent.width
                    size: 24
                    visible: !!(Ui.game.pet && Ui.game.pet.name)
                    text: Ui.game.pet ? Ui.game.pet.name + (Ui.game.pet.petted ? " has been petted" : " wants petting")
                        + (Ui.game.pet.bowl ? ", bowl full" : ", bowl empty") : ""
                    color: Ui.game.pet && (!Ui.game.pet.petted || !Ui.game.pet.bowl) ? Ui.accent : Ui.ink
                }
                Label {
                    width: parent.width
                    size: 24
                    visible: !!Ui.game.mines
                    text: Ui.game.mines ? "Mines: floor " + Ui.game.mines.deepest
                        + (Ui.game.mines.skull > 0 ? " · Skull Cavern: " + Ui.game.mines.skull : "") : ""
                }
                Label {
                    width: parent.width
                    size: 24
                    visible: !!Ui.game.collections
                    text: Ui.game.collections ? "Museum: " + Ui.game.collections.donated + "/" + Ui.game.collections.total
                        + (Ui.game.collections.carried.length ? " · " + Ui.game.collections.carried.length
                           + " in your bag to donate" : "") : ""
                }
                Label {
                    width: parent.width
                    size: 24
                    visible: Ui.game.cooking.length > 0
                    text: "Ready to cook: " + Ui.game.cooking.map(r => r.name).join(", ")
                }
                Label {
                    width: parent.width
                    size: 24
                    visible: !!(Ui.game.day && Ui.game.day.totalEarnings !== undefined)
                    text: Ui.game.day ? "Earned in all: " + Ui.number(Ui.game.day.totalEarnings) + "g" : ""
                    color: Ui.inkSoft
                }
            }
        }
    }
}
