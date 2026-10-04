// The connection to Stardew Valley, and what the game last said.
//
// The Stardew Valley Dual Screen Mod (by Profmags) serves the game on a
// WebSocket, ws://127.0.0.1:7786 by default: one JSON object per frame, each
// with a "type". The newest of each kind is kept here as it arrives; the
// pages bind to these properties. docs/protocol.md lists every message.
import QtQuick
import QtWebSockets

Item {
    id: game

    property string host: "127.0.0.1"
    property int port: 7786

    readonly property bool connected: socket.status === WebSocket.Open
    readonly property string status: {
        switch (socket.status) {
        case WebSocket.Open: return day ? "Connected" : "Connected, waiting for a save"
        case WebSocket.Connecting: return "Connecting…"
        case WebSocket.Error: return "No game at " + host + ":" + port
        default: return "Not connected"
        }
    }
    // A save is loaded (the mod sends nothing else from the title screen).
    readonly property bool inGame: connected && day !== null && saveName !== ""

    property string saveName: ""
    property var config: null       // the mod's options (sdv_config)
    property var day: null          // date, clock, weather, gold, energy, health, place, map position
    property var inventory: null    // {selected, capacity, items: [{slot, id, name, count, ...}]}
    property var skills: null
    property var quests: []
    property var orders: []
    property var villagers: []
    property var gifts: []          // [{name, carrying, loves: [{id, name, carried}]}]
    property var crops: []
    property var trees: []
    property var machines: []
    property var animals: []
    property var pet: null
    property var bundles: []
    property var collections: null  // museum
    property var crafting: []
    property var cooking: []
    property var calendar: null
    property var shipping: null
    property var mines: null
    property bool cartOpen: false
    property var grounds: []        // backdrop tiles to choose from
    // The 2.0 mod sends recipes with their ingredients and can craft them;
    // 0.3 sends only what is ready.
    readonly property bool canCraft: crafting.length > 0 && crafting[0].key !== undefined

    // Pictures: the game's own art, sent once each as PNG. sprite(id) is a
    // data: URL for an Image, or "" until it arrives.
    property int spriteRev: 0
    property var _sprites: ({})
    property var _insets: ({})
    function sprite(id) {
        spriteRev
        return (id && _sprites[id]) || ""
    }
    function inset(id) {
        spriteRev
        return _insets[id] || 0
    }
    function hasSprite(id) { return sprite(id) !== "" }

    // The mod sends flags as "1" and "0".
    readonly property var flagKeys: ["ready", "carried", "carrying", "petted", "baby", "bottomless", "daily",
        "cancellable", "complete", "talkedToday", "needsWater", "open", "bowl", "hideGameHud",
        "allowInventoryEdits", "allowQuestCancel", "farmerMarker", "sendCrops", "sendMachines", "sendAnimals",
        "sendBundles", "sendVillagers", "sendMap", "sendCrafting"]
    function fix(v) {
        if (Array.isArray(v))
            return v.map(fix)
        if (v && typeof v === "object") {
            for (const k in v) {
                if (flagKeys.indexOf(k) >= 0 && typeof v[k] === "string")
                    v[k] = v[k] === "1"
                else if (typeof v[k] === "object")
                    v[k] = fix(v[k])
            }
        }
        return v
    }

    function receive(text) {
        let m
        try { m = JSON.parse(text) } catch (e) { return }
        if (!m || !m.type)
            return
        if (m.type === "sdv_sprite") {
            if (m.id && m.png) {
                _sprites[m.id] = "data:image/png;base64," + m.png
                _insets[m.id] = m.inset || 0
                spriteTick.restart()
            }
            return
        }
        fix(m)
        switch (m.type) {
        case "game_info":
            saveName = m.saveName || ""
            if (!saveName)
                forget()
            break
        case "sdv_config": config = m; break
        case "sdv_day": day = m; break
        case "sdv_inventory": inventory = m; break
        case "sdv_skills": skills = m; break
        case "sdv_quests": quests = m.quests || []; break
        case "sdv_orders": orders = m.orders || []; break
        case "sdv_villagers": villagers = m.villagers || []; break
        case "sdv_gifts": gifts = m.villagers || []; break
        case "sdv_crops": crops = m.crops || []; break
        case "sdv_trees": trees = m.trees || []; break
        case "sdv_machines": machines = m.machines || []; break
        case "sdv_animals": animals = m.animals || []; break
        case "sdv_pet": pet = m; break
        case "sdv_bundles": bundles = m.bundles || []; break
        case "sdv_collections": collections = m; break
        case "sdv_crafting": crafting = m.recipes || []; break
        case "sdv_cooking": cooking = m.recipes || []; break
        case "sdv_calendar": calendar = m; break
        case "sdv_shipping": shipping = m; break
        case "sdv_mines": mines = m; break
        case "sdv_cart": cartOpen = m.open; break
        case "sdv_grounds": grounds = (m.grounds || []).map(g => g.id); break
        }
    }

    // Back to the title screen: nothing of the old save stays on screen.
    function forget() {
        day = null; inventory = null; skills = null; quests = []; orders = []; villagers = []; gifts = []
        crops = []; trees = []; machines = []; animals = []; pet = null; bundles = []; collections = null
        crafting = []; cooking = []; calendar = null; shipping = null; mines = null; cartOpen = false
    }

    // Many pictures come at once; redraw for them together.
    Timer {
        id: spriteTick
        interval: 60
        onTriggered: game.spriteRev++
    }

    // Commands. The mod does them on the game's next frame, and each can be
    // turned off in its options; it then sends what changed.
    function send(o) {
        if (connected)
            socket.sendTextMessage(JSON.stringify(o))
    }
    function selectSlot(slot) { send({ type: "select_slot", slot: slot }) }
    function moveItem(from, to) { send({ type: "move_item", from: from, to: to }) }
    function eatSlot(slot) { send({ type: "eat_slot", slot: slot }) }
    function sortBag() { send({ type: "sort_bag" }) }
    function shiftToolbar(forward) { send({ type: "shift_toolbar", value: forward ? 1 : 0 }) }
    function cancelQuest(index) { send({ type: "cancel_quest", value: index }) }
    function craft(key) { send({ type: "craft_recipe", key: key }) }
    function setOption(key, on) { send({ type: "set_option", key: key, value: on ? 1 : 0 }) }
    function refresh() { send({ type: "refresh" }) }

    function reconnect() {
        socket.active = false
        retry.restart()
        socket.active = true
    }

    WebSocket {
        id: socket
        url: "ws://" + game.host + ":" + game.port
        active: true
        onTextMessageReceived: message => game.receive(message)
        onStatusChanged: function(status) {
            if (status === WebSocket.Open) {
                // The mod sends everything again when a screen attaches, if it
                // takes its HUD off the top screen; ask, in case it doesn't.
                askAll.restart()
            } else if (status === WebSocket.Closed || status === WebSocket.Error) {
                game.saveName = ""
                game.forget()
            }
        }
    }
    onHostChanged: reconnect()
    onPortChanged: reconnect()

    Timer {
        id: askAll
        interval: 1500
        onTriggered: if (!game.day || !game.inventory) game.refresh()
    }

    // Until the game is there: try again every few seconds.
    Timer {
        id: retry
        interval: 3000
        repeat: true
        running: socket.status !== WebSocket.Open && socket.status !== WebSocket.Connecting
        onTriggered: {
            socket.active = false
            socket.active = true
        }
    }
}
