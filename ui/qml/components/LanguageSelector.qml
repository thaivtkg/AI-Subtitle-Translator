import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

RowLayout {
    id: root
    spacing: Theme.spaceMedium
    property alias sourceLang: sourceCombo.currentText

    Text { text: "SOURCE"; color: Theme.textMuted; font.family: Theme.fontUI; font.pixelSize: Theme.fontSizeSmall; font.bold: true }

    ComboBox {
        id: sourceCombo
        model: ["English", "Japanese", "Chinese (Simplified)", "Chinese (Traditional)", "Korean", "Spanish", "French", "German", "Russian"]
        font.family: Theme.fontUI
        font.pixelSize: Theme.fontSizeBody
        implicitWidth: 160
        
        background: Rectangle {
            color: Theme.bgSurfaceElevated
            border.color: Theme.border
            radius: Theme.radius
        }
        contentItem: Text {
            text: sourceCombo.currentText
            color: Theme.textPrimary
            font: sourceCombo.font
            verticalAlignment: Text.AlignVCenter
            leftPadding: Theme.spaceSmall
        }
    }

    Text { text: " ➔ "; color: Theme.textMuted; font.pixelSize: 16; font.bold: true }

    Text { text: "TARGET"; color: Theme.textMuted; font.family: Theme.fontUI; font.pixelSize: Theme.fontSizeSmall; font.bold: true }

    ComboBox {
        id: targetCombo
        model: ["Vietnamese"]
        font.family: Theme.fontUI
        font.pixelSize: Theme.fontSizeBody
        implicitWidth: 120
        enabled: false
        
        background: Rectangle {
            color: Theme.bgSurfaceSoft
            border.color: Theme.border
            radius: Theme.radius
        }
        contentItem: Text {
            text: targetCombo.currentText
            color: Theme.textSecondary
            font: targetCombo.font
            verticalAlignment: Text.AlignVCenter
            leftPadding: Theme.spaceSmall
        }
    }

    function setLanguage(lang) {
        let idx = sourceCombo.find(lang)
        if (idx !== -1) sourceCombo.currentIndex = idx
    }
}