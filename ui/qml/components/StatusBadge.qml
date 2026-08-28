import QtQuick 2.15
import "../theme"

Rectangle {
    id: badge
    property string status: "PENDING"

    implicitWidth: statusText.width + Theme.spaceMedium
    implicitHeight: 20
    radius: 4

    // Đổ nền nhạt (opacity 20%) tùy theo trạng thái
    color: {
        if (status === "ACCEPTED") return Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.2)
        if (status === "TRANSLATING") return Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.2)
        if (status === "TRANSLATED" || status === "EDITED") return Qt.rgba(Theme.accentPurple.r, Theme.accentPurple.g, Theme.accentPurple.b, 0.2)
        if (status === "ERROR") return Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.2)
        return Qt.rgba(Theme.textDisabled.r, Theme.textDisabled.g, Theme.textDisabled.b, 0.2)
    }

    // Viền đậm nét tùy theo trạng thái
    border.color: {
        if (status === "ACCEPTED") return Theme.success
        if (status === "TRANSLATING") return Theme.accentCyan
        if (status === "TRANSLATED" || status === "EDITED") return Theme.accentPurple
        if (status === "ERROR") return Theme.danger
        return Theme.textDisabled
    }
    border.width: 1

    Text {
        id: statusText
        anchors.centerIn: parent
        text: badge.status
        font.pixelSize: 10
        font.bold: true
        color: badge.border.color
    }
}