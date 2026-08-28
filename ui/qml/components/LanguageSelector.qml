import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

RowLayout {
    id: root
    spacing: Theme.spaceMedium
    property alias sourceLang: sourceCombo.currentText

    Text { text: "SOURCE"; color: Theme.textMuted; font.pixelSize: 12; font.bold: true }

    ComboBox {
        id: sourceCombo
        model: ["English", "Japanese", "Chinese (Simplified)", "Chinese (Traditional)", "Korean", "Spanish", "French", "German", "Russian"]
        font.pixelSize: 14
        implicitWidth: 160
    }

    Text { text: " ➔ "; color: Theme.textMuted; font.pixelSize: 16; font.bold: true }

    Text { text: "TARGET"; color: Theme.textMuted; font.pixelSize: 12; font.bold: true }

    ComboBox {
        id: targetCombo
        model: ["Vietnamese"]
        font.pixelSize: 14
        implicitWidth: 120
        enabled: false // Target luôn cố định
    }

    function setLanguage(lang) {
        let idx = sourceCombo.find(lang)
        if (idx !== -1) sourceCombo.currentIndex = idx
    }
}