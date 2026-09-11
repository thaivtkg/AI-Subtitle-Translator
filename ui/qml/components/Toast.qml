import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Rectangle {
    id: root
    // Rộng linh hoạt nhưng có giới hạn tối đa 400px
    width: Math.min(Math.max(messageText.implicitWidth + 70, 250), 400)

    // CAO LINH HOẠT: Tự động đẩy chiều cao nếu chữ rớt dòng
    height: Math.max(48, messageText.implicitHeight + Theme.spaceLarge)
    radius: Theme.radius

    color: Theme.bgSurfaceElevated
    border.color: type === "SUCCESS" ? Theme.accentPrimary : (type === "ERROR" ? Theme.danger : Theme.accentSecondary)
    border.width: 1

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

        Text {
            text: root.type === "SUCCESS" ? "✓" : (root.type === "ERROR" ? "✕" : "ℹ")
            color: root.border.color
            font.family: Theme.fontUI
            font.pixelSize: 18 // Phóng to icon một chút
            font.bold: true
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            id: messageText
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: root.message
            color: Theme.textPrimary
            font.family: Theme.fontUI
            font.pixelSize: Theme.fontSizeBody
            wrapMode: Text.WordWrap
            lineHeight: 1.2 // Giãn dòng nhẹ cho dễ đọc
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
        to: Theme.spaceMedium
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