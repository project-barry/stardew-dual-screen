// Machines, animals, crops and fruit trees, anywhere on the farm and beyond.
import QtQuick

Item {
    id: page
    readonly property real gap: 10 * Ui.s
    readonly property real colWidth: (width - 2 * gap) / 3

    readonly property var machines: Ui.game.machines.slice().sort((a, b) =>
        (b.ready - a.ready) || (a.minutes - b.minutes))
    // Crops in groups of one kind in one place.
    readonly property var fields: {
        const groups = {}
        const out = []
        for (const c of Ui.game.crops) {
            const k = c.name + "|" + c.location
            if (!groups[k]) {
                groups[k] = { id: c.id || "", name: c.name, location: c.location, count: 0, dry: 0, ready: 0,
                              days: 999, tree: false }
                out.push(groups[k])
            }
            const g = groups[k]
            g.count++
            if (c.needsWater) g.dry++
            if (c.ready) g.ready++
            else g.days = Math.min(g.days, c.daysLeft)
        }
        out.sort((a, b) => (b.ready - a.ready) || (b.dry - a.dry) || a.name.localeCompare(b.name))
        for (const t of Ui.game.trees)
            out.push({ id: t.id, name: (t.name || "Fruit") + " tree", location: t.location, count: t.count,
                       dry: 0, ready: t.count, days: 0, tree: true })
        return out
    }
    readonly property int dryCount: Ui.game.crops.filter(c => c.needsWater).length

    component Icon: Item {
        property string sprite
        width: 60 * Ui.s
        height: width
        Pixel { anchors.fill: parent; sprite: parent.sprite }
    }

    ListPanel {
        id: machinesPanel
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: page.colWidth
        title: "Machines"
        note: page.machines.filter(m => m.ready).length + " ready"
        empty: Ui.game.config && !Ui.game.config.sendMachines ? "Off in Settings" : "Nothing in the machines"
        model: page.machines
        delegate: Item {
            required property var modelData
            width: ListView.view.width
            height: 76 * Ui.s
            Row {
                id: pics
                anchors.verticalCenter: parent.verticalCenter
                Icon { sprite: modelData.id }
                Icon { sprite: modelData.outputId; width: 48 * Ui.s; anchors.verticalCenter: parent.verticalCenter }
            }
            Column {
                anchors { left: pics.right; leftMargin: 8 * Ui.s; right: when.left; rightMargin: 6 * Ui.s
                          verticalCenter: parent.verticalCenter }
                Label { width: parent.width; text: modelData.output + (modelData.count > 1 ? " ×" + modelData.count : ""); size: 24; bold: true }
                Label { width: parent.width; text: modelData.name + " · " + modelData.location; size: 20; color: Ui.inkSoft }
            }
            Label {
                id: when
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                text: modelData.ready ? "Ready" : Ui.duration(modelData.minutes)
                color: modelData.ready ? Ui.good : Ui.inkSoft
                size: 24
                bold: modelData.ready
            }
        }
    }

    ListPanel {
        anchors { left: machinesPanel.right; leftMargin: page.gap; top: parent.top; bottom: parent.bottom }
        width: page.colWidth
        title: "Animals"
        note: Ui.game.animals.filter(a => !a.petted).length + " to pet"
        empty: Ui.game.config && !Ui.game.config.sendAnimals ? "Off in Settings" : "No animals yet"
        model: Ui.game.animals
        header: Item {
            width: ListView.view.width
            height: Ui.game.pet && Ui.game.pet.name ? 84 * Ui.s : 0
            visible: height > 0
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8 * Ui.s
                Icon { sprite: "ui:pet" }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Label { text: Ui.game.pet ? Ui.game.pet.name : ""; size: 24; bold: true }
                    Label {
                        text: Ui.game.pet ? (Ui.game.pet.petted ? "Petted" : "Not petted yet")
                                            + " · bowl " + (Ui.game.pet.bowl ? "full" : "empty") : ""
                        size: 20
                        color: Ui.game.pet && (!Ui.game.pet.petted || !Ui.game.pet.bowl) ? Ui.accent : Ui.inkSoft
                    }
                }
            }
        }
        delegate: Item {
            required property var modelData
            width: ListView.view.width
            height: 84 * Ui.s
            Icon {
                id: who
                anchors.verticalCenter: parent.verticalCenter
                sprite: modelData.spriteId || modelData.produceId || ""
            }
            Column {
                anchors { left: who.right; leftMargin: 8 * Ui.s; right: produce.left; verticalCenter: parent.verticalCenter }
                spacing: 2 * Ui.s
                Label {
                    width: parent.width
                    text: modelData.name + (modelData.baby ? " (baby)" : "")
                    size: 24
                    bold: true
                }
                Row {
                    spacing: 8 * Ui.s
                    Hearts { value: modelData.hearts; max: 5; size: 20 * Ui.s; anchors.verticalCenter: parent.verticalCenter }
                    Label {
                        text: modelData.petted ? "petted" : "pet me"
                        size: 20
                        color: modelData.petted ? Ui.inkSoft : Ui.accent
                        bold: !modelData.petted
                    }
                }
            }
            Icon {
                id: produce
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                width: modelData.produceId ? 52 * Ui.s : 0
                sprite: modelData.produceId || ""
            }
        }
    }

    ListPanel {
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
        width: page.colWidth
        title: "Fields"
        note: page.dryCount > 0 ? page.dryCount + " dry" : "all watered"
        empty: Ui.game.config && !Ui.game.config.sendCrops ? "Off in Settings" : "Nothing planted"
        model: page.fields
        delegate: Item {
            required property var modelData
            width: ListView.view.width
            height: Math.max(76 * Ui.s, info.height + 12 * Ui.s)
            Icon { id: crop; sprite: modelData.id; anchors.verticalCenter: parent.verticalCenter }
            Column {
                id: info
                anchors { left: crop.right; leftMargin: 8 * Ui.s; right: parent.right; verticalCenter: parent.verticalCenter }
                Label {
                    width: parent.width
                    text: modelData.count + "× " + modelData.name
                    size: 24
                    bold: true
                }
                Label {
                    width: parent.width
                    size: 20
                    wrapMode: Text.Wrap
                    elide: Text.ElideNone
                    color: modelData.dry > 0 ? Ui.water : modelData.ready > 0 ? Ui.good : Ui.inkSoft
                    text: modelData.location + " · " + (modelData.tree ? "fruit waiting"
                          : [modelData.ready > 0 ? modelData.ready + " ready" : "",
                             modelData.dry > 0 ? modelData.dry + " need water" : "",
                             modelData.ready < modelData.count ? modelData.days + "d to go" : ""]
                            .filter(x => x).join(", "))
                }
            }
        }
    }
}
