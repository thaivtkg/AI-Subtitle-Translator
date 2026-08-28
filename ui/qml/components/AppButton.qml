import QtQuick 2.15
import QtQuick.Controls 2.15
import "../theme"

Button {
    id: control
    property bool isPrimary: false

    contentItem: Text {
        text: control.text
        font.pixelSize: 14
        font.bold: control.isPrimary
        color: !control.enabled ? Theme.textDisabled : (control.isPrimary ? Theme.bgApp : Theme.textPrimary)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        implicitWidth: 100
        implicitHeight: 36
        radius: Theme.radius
        
        color: !control.enabled ? Theme.bgSurfaceElevated :
               control.pressed ? (control.isPrimary ? Qt.darker(Theme.accentCyan, 1.2) : Theme.bgSurfaceSoft) :
               control.hovered ? (control.isPrimary ? Qt.lighter(Theme.accentCyan, 1.1) : Theme.bgSurfaceElevated) :
               (control.isPrimary ? Theme.accentCyan : "transparent")
               
        border.color: (control.isPrimary || !control.enabled) ? "transparent" : Theme.border
        border.width: 1

        Behavior on color { ColorAnimation { duration: Theme.animDuration } }
    }
}