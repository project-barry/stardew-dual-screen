// Sizes, colours and the game, for every part of the app. main.qml sets
// s (Barry Launcher's scale: 1 at the AYN Thor's 1240 x 1080 bottom screen)
// and game.
pragma Singleton
import QtQuick

QtObject {
    property real s: 1
    property var game: null

    // Stardew's menus: cream paper, brown wood, dark brown ink.
    readonly property color paper: "#fbe3ad"
    readonly property color paperDark: "#f0c97f"
    readonly property color wood: "#9c5b2a"
    readonly property color woodDark: "#5e2f12"
    readonly property color ink: "#3d1e0c"
    readonly property color inkSoft: "#7a4a26"
    readonly property color accent: "#d8742c"
    readonly property color good: "#3f8f2f"
    readonly property color bad: "#b83224"
    readonly property color water: "#3a86d6"
    readonly property color gold: "#e7a923"
    readonly property color pressed: "#e8b665"
    readonly property string font: "Noto Sans"

    // Stardew's clock: 610 -> "6:10 am", 2400 -> "12:00 am", 2530 -> "1:30 am".
    function clock(t) {
        if (t === undefined || t === null)
            return ""
        const h = Math.floor(t / 100) % 24, m = t % 100
        return (h % 12 === 0 ? 12 : h % 12) + ":" + (m < 10 ? "0" : "") + m + (h < 12 ? " am" : " pm")
    }
    // Game minutes as days, hours and minutes.
    function duration(minutes) {
        if (minutes <= 0)
            return "Ready"
        const d = Math.floor(minutes / 1440), h = Math.floor(minutes % 1440 / 60), m = minutes % 60
        if (d > 0)
            return d + "d " + (h > 0 ? h + "h" : "")
        return (h > 0 ? h + "h " : "") + (m > 0 ? m + "m" : "")
    }
    function number(n) { return (n || 0).toLocaleString(Qt.locale("en_US"), "f", 0) }
    // The fortune teller's words for the day's luck (thousandths).
    function luck(l) {
        if (l === undefined) return ""
        if (l > 70) return "The spirits are very happy today"
        if (l > 20) return "The spirits are in good humor today"
        if (l >= -20) return l === 0 ? "The spirits feel neutral today" : "The spirits are somewhat mildly perplexed"
        if (l >= -70) return "The spirits are somewhat annoyed today"
        return "The spirits are very displeased today"
    }
    function luckColor(l) { return l > 20 ? good : l < -20 ? bad : inkSoft }
    readonly property var qualityColors: ["transparent", "#c9d3dc", "#f2c230", "#000000", "#b36af0"]
}
