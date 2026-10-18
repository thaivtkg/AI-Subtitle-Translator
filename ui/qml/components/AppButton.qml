import QtQuick 2.15
import QtQuick.Controls 2.15
import "../theme"

Button {
    id: control
    property bool isPrimary: false
    property string tooltip: ""

    implicitWidth: Math.max(80, contentItem.implicitWidth + Theme.spaceLarge)
    implicitHeight: 32

    ToolTip.visible: hovered && tooltip !== ""
    ToolTip.text: tooltip
    ToolTip.delay: 400
    ToolTip.timeout: 3000

    contentItem: Text {
        text: control.text
        font.pixelSize: 13
        font.bold: true
        color: !control.enabled ? Qt.rgba(1, 1, 1, 0.45) : Theme.textPrimaryGlass
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        implicitWidth: 100
        implicitHeight: 32
        radius: control.height / 2

        color: !control.enabled ? Qt.rgba(1, 1, 1, 0.10) :
               control.pressed ? (control.isPrimary ? Qt.darker(Theme.accentSapphire, 1.2) : Qt.rgba(1, 1, 1, 0.16)) :
               control.hovered ? (control.isPrimary ? Theme.accentSapphireHover : Qt.rgba(1, 1, 1, 0.32)) :
               (control.isPrimary ? Theme.accentSapphire : Qt.rgba(1, 1, 1, 0.22))

        border.color: !control.enabled ? Qt.rgba(1, 1, 1, 0.18) :
                      control.hovered ? Theme.glassBorderSpecularUpper :
                      (control.isPrimary ? Theme.glassBorderSpecularUpper : Theme.glassBorderSubtle)
        border.width: 1

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 1
            height: 1
            color: Qt.rgba(1, 1, 1, 0.35)
            radius: parent.radius
            visible: control.enabled
        }

        Behavior on color { ColorAnimation { duration: Theme.animHover; easing.type: Easing.OutQuad } }
        Behavior on border.color { ColorAnimation { duration: Theme.animHover; easing.type: Easing.OutQuad } }
    }
}

