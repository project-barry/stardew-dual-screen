// Recipes. With the 2.0 mod: every known recipe, its ingredients (what you
// have of each), and Craft. With 0.3: what you can craft now.
import QtQuick

Item {
    id: page
    property bool readyOnly: false
    readonly property bool editable: !Ui.game.config || Ui.game.config.allowInventoryEdits
    readonly property var recipes: {
        const all = Ui.game.crafting.slice()
        if (!Ui.game.canCraft)
            return all.map(r => Object.assign({ ready: true, ingredients: [] }, r))
        const shown = readyOnly ? all.filter(r => r.ready) : all
        return shown.sort((a, b) => (b.ready - a.ready) || a.name.localeCompare(b.name))
    }

    ListPanel {
        id: list
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: parent.width * 0.7
        title: Ui.game.canCraft ? "Crafting" : "Ready to craft"
        note: Ui.game.crafting.filter(r => r.ready !== false).length + " ready"
        empty: Ui.game.config && !Ui.game.config.sendCrafting ? "Off in Settings"
             : page.readyOnly || !Ui.game.canCraft ? "Nothing you can craft with what you carry" : "No recipes yet"
        model: page.recipes
        delegate: Rectangle {
            id: r
            required property var modelData
            width: ListView.view.width
            height: Math.max(110 * Ui.s, body.height + 22 * Ui.s)
            radius: 8 * Ui.s
            color: modelData.ready ? "#fff1cf" : "#f1d29a"
            border { color: modelData.ready ? Ui.good : Ui.wood; width: 3 * Ui.s }
            Pixel {
                id: pic
                anchors { left: parent.left; leftMargin: 10 * Ui.s; verticalCenter: parent.verticalCenter }
                width: 72 * Ui.s
                height: width
                sprite: r.modelData.id
                opacity: r.modelData.ready ? 1 : 0.55
            }
            Column {
                id: body
                anchors { left: pic.right; leftMargin: 12 * Ui.s; right: craft.left; rightMargin: 10 * Ui.s
                          verticalCenter: parent.verticalCenter }
                spacing: 6 * Ui.s
                Label {
                    width: parent.width
                    text: r.modelData.name + (r.modelData.outputCount > 1 ? " ×" + r.modelData.outputCount : "")
                          + (r.modelData.crafted > 0 ? "   (made " + r.modelData.crafted + ")" : "")
                    size: 26
                    bold: true
                }
                Label {
                    width: parent.width
                    visible: !!r.modelData.description
                    text: r.modelData.description || ""
                    size: 20
                    color: Ui.inkSoft
                }
                Flow {
                    width: parent.width
                    spacing: 6 * Ui.s
                    visible: r.modelData.ingredients.length > 0
                    Repeater {
                        model: r.modelData.ingredients
                        Chip {
                            required property var modelData
                            sprite: modelData.id
                            text: modelData.have + "/" + modelData.required
                            showName: true
                            count: 1
                            lacking: modelData.have < modelData.required
                            implicitHeight: 52 * Ui.s
                        }
                    }
                }
            }
            Button {
                id: craft
                anchors { right: parent.right; rightMargin: 10 * Ui.s; verticalCenter: parent.verticalCenter }
                visible: Ui.game.canCraft
                width: visible ? implicitWidth : 0
                text: "Craft"
                enabled: r.modelData.ready && page.editable
                onClicked: Ui.game.craft(r.modelData.key)
            }
        }
    }

    Column {
        anchors { left: list.right; leftMargin: 10 * Ui.s; right: parent.right; top: parent.top }
        spacing: 10 * Ui.s
        Button {
            width: parent.width
            visible: Ui.game.canCraft
            text: page.readyOnly ? "Show all" : "Only ready"
            active: page.readyOnly
            onClicked: page.readyOnly = !page.readyOnly
        }
        Panel {
            width: parent.width
            height: cookCol.implicitHeight + 2 * padding
            Column {
                id: cookCol
                width: parent.width
                spacing: 8 * Ui.s
                Label { text: "Ready to cook"; size: 28; bold: true }
                Label {
                    visible: Ui.game.cooking.length === 0
                    width: parent.width
                    text: "Nothing, with what you carry"
                    size: 22
                    color: Ui.inkSoft
                    wrapMode: Text.Wrap
                    elide: Text.ElideNone
                }
                Repeater {
                    model: Ui.game.cooking
                    Chip {
                        required property var modelData
                        sprite: modelData.id
                        text: modelData.name
                    }
                }
            }
        }
        Label {
            width: parent.width
            visible: Ui.game.canCraft && !page.editable
            text: "Crafting needs the mod's \"Inventory edits\" option (Settings)."
            wrapMode: Text.Wrap
            elide: Text.ElideNone
            size: 22
            color: "white"
            style: Text.Outline
            styleColor: Ui.woodDark
        }
    }
}
