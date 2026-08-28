import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Item {
    id: workspace
    
    property bool hasSelection: false
    signal translateRequested(string sourceLang)
    signal acceptRequested(string text)

    function setSourceLanguage(lang) { langSelector.setLanguage(lang) }
    function getSourceLanguage() { return langSelector.sourceLang }

    // ==========================================
    // 1. TRẠNG THÁI TRỐNG
    // ==========================================
    EmptyWorkspace {
        anchors.fill: parent
        visible: !workspace.hasSelection
    }

    // ==========================================
    // 2. KHỐI EDITOR CHÍNH
    // ==========================================
    ColumnLayout {
        anchors.fill: parent
        visible: workspace.hasSelection
        spacing: Theme.space16

        // --- TOOLBAR ---
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Theme.space8
            
            LanguageSelector { id: langSelector }
            
            Item { Layout.fillWidth: true } 
            
            RowLayout {
                spacing: Theme.space8
                Text { text: "Status:"; color: Theme.textMuted; font.family: Theme.fontUI; font.pixelSize: Theme.fontCaption }
                StatusBadge { status: translationController.status }
            }
        }

        // --- BẢN GỐC (ORIGINAL) ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: workspace.height * 0.35
            spacing: Theme.space8

            Text { 
                text: "ORIGINAL"
                color: Theme.textSecondary
                font.family: Theme.fontUI
                font.pixelSize: Theme.fontCaption
                font.bold: true 
                Layout.leftMargin: Theme.space4
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.bgSurface // Nền chìm
                radius: 6
                border.width: 0 // Xóa viền hoàn toàn cho cảm giác read-only

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: Theme.space12
                    TextArea {
                        text: translationController.currentOriginal
                        color: Theme.textSecondary
                        font.family: Theme.fontUI
                        font.pixelSize: Theme.fontBody + 1 // To hơn body thường một chút
                        wrapMode: Text.WordWrap
                        readOnly: true
                        selectByMouse: true
                        background: null
                    }
                }
            }
        }

        // --- BẢN DỊCH (VIETNAMESE) ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.space8

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.space4
                Layout.rightMargin: Theme.space4
                
                Text { 
                    text: "VIETNAMESE"
                    color: Theme.textPrimary
                    font.family: Theme.fontUI
                    font.pixelSize: Theme.fontCaption
                    font.bold: true 
                }
                Item { Layout.fillWidth: true }
                Text { 
                    text: "EDITABLE ✎"
                    color: Theme.textMuted
                    font.family: Theme.fontUI
                    font.pixelSize: Theme.fontCaption 
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.bgSurfaceElevated // Nền nổi bật
                radius: 6
                // Chỉ hiện viền Accent khi người dùng đang click vào để gõ
                border.color: translationInput.activeFocus ? Theme.accentSecondary : Theme.border
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 150 } }

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: Theme.space12
                    TextArea {
                        id: translationInput
                        text: translationController.currentTranslation
                        color: Theme.textPrimary
                        font.family: Theme.fontUI
                        font.pixelSize: Theme.fontBody + 3 // Hero text (Rất to và rõ)
                        wrapMode: Text.WordWrap
                        selectByMouse: true
                        background: null

                        onTextChanged: {
                            if (translationInput.focus && 
                                translationController.status !== "TRANSLATING" &&
                                translationInput.text !== translationController.currentTranslation) {
                                translationController.markAsEdited()
                                hasUnsavedChanges = true 
                            }
                        }
                        
                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Return && (event.modifiers & Qt.ControlModifier)) {
                                event.accepted = true
                                if (translationController.status === "TRANSLATED" || 
                                    translationController.status === "EDITED" || 
                                    translationController.status === "ACCEPTED") {
                                    acceptRequested(translationInput.text)
                                    hasUnsavedChanges = true
                                }
                            }
                        }
                    }
                }
            }
        }

        // --- ACTION BAR ---
        RowLayout {
            Layout.alignment: Qt.AlignRight
            Layout.bottomMargin: Theme.space8
            spacing: Theme.space12

            AppButton {
                text: "↻ Retry"
                enabled: translationController.status !== "TRANSLATING"
                onClicked: translateRequested(langSelector.sourceLang)
            }
            
            Button {
                id: translateBtn
                text: translationController.status === "TRANSLATING" ? "◌ Translating..." : "✦ Translate"
                enabled: translationController.status !== "TRANSLATING"
                font.family: Theme.fontUI
                font.pixelSize: Theme.fontLabel
                font.bold: true
                
                contentItem: Text {
                    text: translateBtn.text; font: translateBtn.font
                    color: !translateBtn.enabled ? Theme.textDisabled : Theme.bgApp
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    implicitWidth: 120; implicitHeight: 32; radius: 4
                    color: !translateBtn.enabled ? Theme.bgSurfaceSoft : Theme.accentSecondary
                }
                onClicked: translateRequested(langSelector.sourceLang)
            }

            Button {
                id: acceptBtn
                text: "✓ Accept"
                enabled: translationController.status === "TRANSLATED" || translationController.status === "EDITED" || translationController.status === "ACCEPTED"
                font.family: Theme.fontUI
                font.pixelSize: Theme.fontLabel
                font.bold: true
                
                contentItem: Text {
                    text: acceptBtn.text; font: acceptBtn.font
                    color: !acceptBtn.enabled ? Theme.textDisabled : Theme.bgApp
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    implicitWidth: 100; implicitHeight: 32; radius: 4
                    color: !acceptBtn.enabled ? Theme.bgSurfaceSoft : Theme.accentPrimary
                }
                onClicked: acceptRequested(translationInput.text)
            }
        }
    }
}