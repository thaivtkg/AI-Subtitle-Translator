import QtQuick 2.15
import QtQuick.Controls 2.15
import "../theme"

Button {
    id: control
    property bool isPrimary: false
    property string tooltip: ""

    implicitWidth: Math.max(80, contentItem.implicitWidth + Theme.spaceLarge)
    implicitHeight: 32

    z: 1

    ToolTip.visible: hovered && tooltip !== ""
    ToolTip.text: tooltip
    ToolTip.delay: 400
    ToolTip.timeout: 3000

    contentItem: Text {
        text: control.text
        font.pixelSize: 13
        font.bold: true
        color: !control.enabled ? Qt.rgba(1, 1, 1, 0.45) : (control.isPrimary ? "#FFFFFF" : Theme.textPrimaryGlass)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        implicitWidth: 100
        implicitHeight: 32
        radius: control.height / 2

        color: !control.enabled ? (control.isPrimary ? Qt.rgba(0, 102, 255, 0.4) : Qt.rgba(1, 1, 1, 0.12)) :
               control.pressed ? (control.isPrimary ? "#0052CC" : Qt.rgba(1, 1, 1, 0.20)) :
               control.hovered ? (control.isPrimary ? "#1A75FF" : Qt.rgba(1, 1, 1, 0.38)) :
               (control.isPrimary ? Theme.accentSapphire : Qt.rgba(1, 1, 1, 0.28))

        border.color: !control.enabled ? Qt.rgba(1, 1, 1, 0.20) :
                      control.hovered ? Qt.rgba(1, 1, 1, 0.90) :
                      (control.isPrimary ? Qt.rgba(1, 1, 1, 0.80) : Qt.rgba(1, 1, 1, 0.60))
        border.width: 1

        Behavior on color { ColorAnimation { duration: Theme.animHover; easing.type: Easing.OutQuad } }
        Behavior on border.color { ColorAnimation { duration: Theme.animHover; easing.type: Easing.OutQuad } }
    }
}

