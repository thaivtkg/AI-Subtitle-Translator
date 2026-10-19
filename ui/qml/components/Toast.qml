import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import "../theme"

Rectangle {
    id: root
    // Rộng linh hoạt nhưng có giới hạn tối đa 440px
    width: Math.min(Math.max(messageText.implicitWidth + 80, 260), 440)

    // CAO LINH HOẠT: Tự động đẩy chiều cao nếu chữ rớt dòng
    height: Math.max(46, messageText.implicitHeight + Theme.spaceLarge)
    radius: Math.min(23, height / 2)

    // Luminous Frosted Glass Capsule
    color: Qt.rgba(1.0, 1.0, 1.0, 0.94)
    border.color: Theme.glassBorderSpecularUpper
    border.width: 1.5

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0.0, 0.15, 0.35, 0.22)
        shadowBlur: 0.50
        shadowVerticalOffset: 4
    }

    property string message: ""
    property string type: "INFO"

    y: -height - 20
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
    z: 999

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spaceSmall
        anchors.leftMargin: Theme.spaceMedium
        anchors.rightMargin: Theme.spaceMedium
        spacing: Theme.spaceMedium

        // Icon capsule
        Rectangle {
            width: 26
            height: 26
            radius: 13
            color: root.type === "SUCCESS" ? Qt.rgba(0.13, 0.77, 0.37, 0.15) : (root.type === "ERROR" ? Qt.rgba(0.94, 0.27, 0.27, 0.15) : Qt.rgba(0.0, 0.45, 1.0, 0.15))
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: root.type === "SUCCESS" ? "✓" : (root.type === "ERROR" ? "✕" : "ℹ")
                color: root.type === "SUCCESS" ? "#10B981" : (root.type === "ERROR" ? "#EF4444" : "#0284C7")
                font.pixelSize: 13
                font.bold: true
            }
        }

        Text {
            id: messageText
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: root.message
            color: Theme.textOnLightPod
            font.pixelSize: 13
            font.bold: true
            wrapMode: Text.WordWrap
            lineHeight: 1.2
        }
    }

    Timer {
        id: hideTimer
        interval: 3000
        onTriggered: hide()
    }

    function show(title, msg) {
        root.type = title
        root.message = msg
        hideTimer.restart()
        slideIn.start()
    }

    function hide() {
        slideOut.start()
    }

    NumberAnimation on y {
        id: slideIn
        to: Theme.spaceLarge + 8
        duration: 250
        easing.type: Easing.OutBack
        running: false
    }

    NumberAnimation on y {
        id: slideOut
        to: -root.height - 20
        duration: 200
        easing.type: Easing.InQuad
        running: false
    }
}
