import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

RowLayout {
    id: root
    property alias sourceLang: sourceCombo.currentText
    property bool compact: false

    spacing: root.compact ? Theme.spaceXs : Theme.spaceMedium

    Text { text: "SOURCE"; color: Theme.textMuted; font.pixelSize: 12; font.bold: true }

    ComboBox {
        id: sourceCombo
        model: ["English", "Japanese", "Chinese (Simplified)", "Chinese (Traditional)", "Korean", "Spanish", "French", "German", "Russian"]
        font.pixelSize: 14
        Layout.minimumWidth: 110
        Layout.preferredWidth: 160
        Layout.maximumWidth: 180
        Layout.fillWidth: true
        contentItem: Text {
            text: sourceCombo.currentText
            color: Theme.textPrimary
            font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter
            leftPadding: Theme.spaceSmall
            elide: Text.ElideRight
        }
        background: Rectangle {
            color: Theme.bgApp
            radius: Theme.radius
            border.color: Theme.border
        }
    }

    Text { text: root.compact ? "→" : " ➔ "; color: Theme.textMuted; font.pixelSize: 16; font.bold: true }

    Text { text: "TARGET"; color: Theme.textMuted; font.pixelSize: 12; font.bold: true }

    ComboBox {
        id: targetCombo
        model: ["Vietnamese"]
        font.pixelSize: 14
        Layout.minimumWidth: 95
        Layout.preferredWidth: 120
        Layout.maximumWidth: 140
        Layout.fillWidth: true
        contentItem: Text {
            text: targetCombo.currentText
            color: Theme.textPrimary
            font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter
            leftPadding: Theme.spaceSmall
            elide: Text.ElideRight
        }
        background: Rectangle {
            color: Theme.bgApp
            radius: Theme.radius
            border.color: Theme.border
        }
        enabled: false // Target luôn cố định
    }

    function setLanguage(lang) {
        let idx = sourceCombo.find(lang)
        if (idx !== -1) sourceCombo.currentIndex = idx
    }
}
