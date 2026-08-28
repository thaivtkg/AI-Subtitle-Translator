import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

ColumnLayout {
    id: workspace
    spacing: Theme.spaceMedium
    
    property bool hasSelection: false
    signal translateRequested(string sourceLang)
    signal acceptRequested(string text)

    // Hàm gọi từ bên ngoài
    function setSourceLanguage(lang) { langSelector.setLanguage(lang) }
    function getSourceLanguage() { return langSelector.sourceLang }

    // Thanh chọn Ngôn ngữ
    LanguageSelector {
        id: langSelector
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Theme.spaceSmall
    }

    // Badge Trạng thái
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Theme.spaceSmall
        Text { text: "State:"; color: Theme.textMuted; font.pixelSize: 14 }
        StatusBadge { status: translationController.status }
    }

    // Ô Tiếng Anh (Bản gốc) - ReadOnly
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 120
        color: Theme.bgSurfaceElevated
        radius: Theme.radius
        border.color: Theme.border
        border.width: 1

        ScrollView {
            anchors.fill: parent
            anchors.margins: Theme.spaceMedium
            TextArea {
                text: translationController.currentOriginal
                color: Theme.textPrimary
                font.pixelSize: 16
                wrapMode: Text.WordWrap
                readOnly: true
                selectByMouse: true
                background: null
            }
        }
        Text {
            text: "ORIGINAL"
            color: Theme.textMuted
            font.pixelSize: 10; font.bold: true
            anchors.right: parent.right; anchors.top: parent.top; anchors.margins: Theme.spaceSmall
        }
    }

    // Ô Tiếng Việt (Bản dịch) - Editable
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Theme.bgSurfaceSoft
        radius: Theme.radius
        border.color: translationController.status === "TRANSLATING" ? Theme.accentCyan : Theme.border
        border.width: translationController.status === "TRANSLATING" ? 2 : 1
        
        Behavior on border.color { ColorAnimation { duration: Theme.animDuration } }

        ScrollView {
            anchors.fill: parent
            anchors.margins: Theme.spaceMedium
            TextArea {
                id: translationInput
                text: translationController.currentTranslation
                color: Theme.accentCyan
                font.pixelSize: 18
                wrapMode: Text.WordWrap
                selectByMouse: true
                background: null

                // Chỉ giữ lại 1 khối onTextChanged
                onTextChanged: {
                    if (translationInput.focus && 
                        translationController.status !== "TRANSLATING" &&
                        translationInput.text !== translationController.currentTranslation) {
                        translationController.markAsEdited()
                    }
                }
                
                // Khối phím tắt Ctrl + Enter
                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Return && (event.modifiers & Qt.ControlModifier)) {
                        event.accepted = true // Chặn hành vi xuống dòng mặc định
                        if ((translationController.status === "TRANSLATED" || 
                             translationController.status === "EDITED" || 
                             translationController.status === "ACCEPTED") && workspace.hasSelection) {
                            acceptRequested(translationInput.text)
                        }
                    }
                }
            }
        }
        Text {
            text: "VIETNAMESE"
            color: Theme.textMuted
            font.pixelSize: 10; font.bold: true
            anchors.right: parent.right; anchors.top: parent.top; anchors.margins: Theme.spaceSmall
        }
    }

    // S2-T7: Action Bar
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.bottomMargin: Theme.spaceSmall
        spacing: Theme.spaceMedium

        AppButton {
            text: "↻ Retry"
            enabled: translationController.status !== "TRANSLATING" && hasSelection
            onClicked: translateRequested(langSelector.sourceLang)
        }
        AppButton {
            text: "✦ AI Translate"
            isPrimary: true
            enabled: translationController.status !== "TRANSLATING" && hasSelection
            onClicked: translateRequested(langSelector.sourceLang)
        }
        AppButton {
            text: "✓ Accept"
            enabled: (translationController.status === "TRANSLATED" || translationController.status === "EDITED" || translationController.status === "ACCEPTED") && hasSelection
            onClicked: acceptRequested(translationInput.text)
        }
    }
}