// A picture from the game, scaled up without smoothing as pixel art is.
// Shows nothing until the game has sent it.
import QtQuick

Image {
    property string sprite
    source: Ui.game ? Ui.game.sprite(sprite) : ""
    smooth: false
    mipmap: false
    fillMode: Image.PreserveAspectFit
    asynchronous: false
}
