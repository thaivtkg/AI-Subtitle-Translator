import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Effects
import "../theme"

Button {
    id: control
    property bool isPrimary: false
    property bool isDarkGlass: false
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
        font.pixelSize: 12
        font.bold: true
        color: !control.enabled ? Qt.rgba(1, 1, 1, 0.45) : "#FFFFFF"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        id: btnBg
        implicitWidth: 100
        implicitHeight: 32
        radius: control.height / 2

        // Đổ bóng phát sáng nhẹ cho nút
        layer.enabled: control.enabled
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: control.isPrimary ? Qt.rgba(0.0, 0.35, 1.0, 0.45) : Qt.rgba(0.0, 0.0, 0.0, 0.18)
            shadowBlur: 0.4
            shadowVerticalOffset: 3
        }

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0.0
                color: !control.enabled ? Qt.rgba(1, 1, 1, 0.12) :
                       control.isPrimary ? (control.pressed ? "#1D4ED8" : (control.hovered ? "#3B82F6" : "#2563EB")) :
                       control.isDarkGlass ? (control.hovered ? Theme.glassDarkPillHover : Theme.glassDarkPill) :
                       (control.hovered ? Qt.rgba(1, 1, 1, 0.35) : Qt.rgba(1, 1, 1, 0.22))
            }
            GradientStop {
                position: 1.0
                color: !control.enabled ? Qt.rgba(1, 1, 1, 0.12) :
                       control.isPrimary ? (control.pressed ? "#4338CA" : (control.hovered ? "#6366F1" : "#4F46E5")) :
                       control.isDarkGlass ? (control.hovered ? Theme.glassDarkPillHover : Theme.glassDarkPill) :
                       (control.hovered ? Qt.rgba(1, 1, 1, 0.28) : Qt.rgba(1, 1, 1, 0.16))
            }
        }

        border.color: !control.enabled ? Qt.rgba(1, 1, 1, 0.20) :
                      control.hovered ? Qt.rgba(1, 1, 1, 0.95) :
                      (control.isPrimary ? Qt.rgba(1, 1, 1, 0.75) : Qt.rgba(1, 1, 1, 0.45))
        border.width: 1

        // Vệt hắt sáng mép trên (Top Specular Gleam)
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: parent.radius * 0.6
            anchors.rightMargin: parent.radius * 0.6
            anchors.topMargin: 1
            height: 1
            color: Qt.rgba(1, 1, 1, control.isPrimary ? 0.65 : 0.45)
        }
    }
}

