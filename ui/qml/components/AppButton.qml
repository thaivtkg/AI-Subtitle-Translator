import QtQuick 2.15
import QtQuick.Controls 2.15
import "../theme"

Button {
    id: control
    property bool isPrimary: false

    // Thêm không gian thở cho nút (Padding)
    leftPadding: Theme.spaceMedium
    rightPadding: Theme.spaceMedium

    contentItem: Text {
        text: control.text
        font.family: Theme.fontUI
        font.pixelSize: Theme.fontSizeBody
        font.bold: control.isPrimary
        color: !control.enabled ? Theme.textDisabled : (control.isPrimary ? "#FFFFFF" : Theme.textPrimary)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        // Tự động giãn chiều rộng theo chữ, tối thiểu 100px
        implicitWidth: Math.max(100, control.contentItem.implicitWidth + control.leftPadding + control.rightPadding)
        implicitHeight: 32
        radius: Theme.radius

        color: !control.enabled ? Theme.bgSurfaceSoft :
               control.pressed ? (control.isPrimary ? Qt.darker(Theme.accentSecondary, 1.2) : Theme.bgSurfaceElevated) :
               control.hovered ? (control.isPrimary ? Qt.lighter(Theme.accentSecondary, 1.1) : Theme.bgSurfaceSoft) :
               (control.isPrimary ? Theme.accentSecondary : "transparent")

        border.color: (control.isPrimary || !control.enabled) ? "transparent" : Theme.border
        border.width: 1

        Behavior on color { ColorAnimation { duration: Theme.animDuration } }
    }
}