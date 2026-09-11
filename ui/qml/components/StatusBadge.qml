import QtQuick 2.15
import "../theme"

Rectangle {
    id: badge
    property string status: "PENDING"

    implicitWidth: statusText.width + Theme.spaceSmall * 2
    implicitHeight: 18
    radius: 2 // Bo góc sắc sảo hơn

    // Nền mờ (Opacity 15%)
    color: {
        if (status === "ACCEPTED") return Qt.rgba(Theme.accentPrimary.r, Theme.accentPrimary.g, Theme.accentPrimary.b, 0.15)
        if (status === "TRANSLATING") return Qt.rgba(Theme.accentSecondary.r, Theme.accentSecondary.g, Theme.accentSecondary.b, 0.15)
        if (status === "TRANSLATED" || status === "EDITED") return Qt.rgba(Theme.accentMuted.r, Theme.accentMuted.g, Theme.accentMuted.b, 0.15)
        if (status === "ERROR") return Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.15)
        return "transparent"
    }

    // Viền chìm
    border.color: {
        if (status === "ACCEPTED") return Qt.rgba(Theme.accentPrimary.r, Theme.accentPrimary.g, Theme.accentPrimary.b, 0.5)
        if (status === "TRANSLATING") return Theme.accentSecondary
        if (status === "TRANSLATED" || status === "EDITED") return Theme.accentMuted
        if (status === "ERROR") return Theme.danger
        return Theme.border
    }
    border.width: 1

    Text {
        id: statusText
        anchors.centerIn: parent
        // Custom Ký hiệu
        text: badge.status === "PENDING" ? "○ PENDING" :
              badge.status === "TRANSLATING" ? "◉ TRANSLATING" :
              badge.status === "ACCEPTED" ? "✓ ACCEPTED" : badge.status

        font.family: Theme.fontUI
        font.pixelSize: Theme.fontSizeBadge
        font.bold: true
        color: badge.status === "PENDING" ? Theme.textMuted : badge.border.color
    }
}