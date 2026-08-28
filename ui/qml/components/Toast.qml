import QtQuick 2.15
import QtQuick.Controls 2.15
import "../theme"

Rectangle {
    id: root
    width: Math.min(Math.max(messageText.width + Theme.spaceXl * 2, 250), 600)
    height: messageText.height + Theme.spaceLarge
    radius: Theme.radius
    
    color: Theme.bgSurfaceElevated
    border.color: type === "SUCCESS" ? Theme.success : (type === "ERROR" ? Theme.danger : Theme.accentCyan)
    border.width: 1

    property string message: ""
    property string type: "INFO" // SUCCESS, ERROR, INFO

    // Đặt vị trí mặc định giấu lên trên cùng màn hình
    y: -height - 20
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
    z: 999 // Đảm bảo luôn nổi lên trên cùng

    Text {
        id: messageText
        text: root.message
        color: Theme.textPrimary
        font.pixelSize: 14
        font.bold: true
        anchors.centerIn: parent
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
    }

    Timer {
        id: hideTimer
        interval: 3000 // Tự tắt sau 3 giây
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
        easing.type: Easing.OutBack // Hiệu ứng nảy nhẹ
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