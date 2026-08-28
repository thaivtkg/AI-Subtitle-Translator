import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

// Đổi root thành Item để chứa 2 trạng thái luân phiên
Item {
    id: workspace
    
    property bool hasSelection: false
    signal translateRequested(string sourceLang)
    signal acceptRequested(string text)

    function setSourceLanguage(lang) { langSelector.setLanguage(lang) }
    function getSourceLanguage() { return langSelector.sourceLang }

    // ==========================================
    // 1. TRẠNG THÁI TRỐNG (Khi chưa chọn câu)
    // ==========================================
    EmptyWorkspace {
        anchors.fill: parent
        visible: !workspace.hasSelection
    }

    // ==========================================
    // 2. KHỐI EDITOR (Khi đã chọn câu thoại)
    // ==========================================
    ColumnLayout {
        anchors.fill: parent
        visible: workspace.hasSelection
        spacing: Theme.spaceMedium

        // --- TOOLBAR BIÊN TẬP ---
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Theme.spaceSmall
            
            LanguageSelector { id: langSelector }
            
            Item { Layout.fillWidth: true } 
            
            RowLayout {
                spacing: Theme.spaceSmall
                Text { text: "Status:"; color: Theme.textMuted; font.family: Theme.fontUI; font.pixelSize: Theme.fontSizeBody }
                StatusBadge { status: translationController.status }
            }
        }

        // --- BẢN GỐC (ORIGINAL) ---
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: workspace.height * 0.4
            Layout.minimumHeight: 100
            color: Theme.bgApp 
            radius: Theme.radius
            border.width: 0 // Đã xóa viền theo thiết kế mới[cite: 4]

            // Tiêu đề khối
            Rectangle {
                width: parent.width; height: 28
                color: Theme.bgSurface
                radius: Theme.radius
                Rectangle { width: parent.width; height: 4; anchors.bottom: parent.bottom; color: Theme.bgSurface }
                Rectangle { width: parent.width; height: 1; anchors.bottom: parent.bottom; color: Theme.border }
                
                Text {
                    text: "ORIGINAL"
                    color: Theme.textSecondary
                    font.family: Theme.fontUI
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Theme.spaceMedium
                }
            }

            ScrollView {
                anchors.fill: parent
                anchors.topMargin: 28
                anchors.margins: Theme.spaceMedium
                TextArea {
                    text: translationController.currentOriginal
                    color: Theme.textSecondary
                    font.family: Theme.fontUI
                    font.pixelSize: 15
                    wrapMode: Text.WordWrap
                    readOnly: true
                    selectByMouse: true
                    background: null
                }
            }
        }

        // --- BẢN DỊCH (TRANSLATION) ---
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: workspace.height * 0.6
            color: Theme.bgSurfaceElevated 
            radius: Theme.radius
            // Viền Accent khi focus
            border.color: translationInput.activeFocus ? Theme.accentSecondary : "transparent"
            border.width: 1

            // Tiêu đề khối
            Rectangle {
                width: parent.width; height: 28
                color: "transparent"
                Text {
                    text: "VIETNAMESE"
                    color: Theme.textPrimary
                    font.family: Theme.fontUI
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Theme.spaceMedium
                }
                Text {
                    text: "EDITABLE ✎"
                    color: Theme.textMuted
                    font.family: Theme.fontUI
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: Theme.spaceMedium
                }
            }

            ScrollView {
                anchors.fill: parent
                anchors.topMargin: 28
                anchors.margins: Theme.spaceMedium
                TextArea {
                    id: translationInput
                    text: translationController.currentTranslation
                    color: Theme.textPrimary
                    font.family: Theme.fontUI
                    font.pixelSize: 18 // Tăng font size thành Hero component
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

        // --- ACTION BAR CHUYÊN NGHIỆP ---
        RowLayout {
            Layout.alignment: Qt.AlignRight
            Layout.bottomMargin: Theme.spaceSmall
            spacing: Theme.spaceMedium

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
                font.pixelSize: Theme.fontSizeBody
                font.bold: true
                
                contentItem: Text {
                    text: translateBtn.text; font: translateBtn.font
                    color: !translateBtn.enabled ? Theme.textDisabled : Theme.bgApp
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    implicitWidth: 120; implicitHeight: 32; radius: Theme.radius
                    color: !translateBtn.enabled ? Theme.bgSurfaceSoft : Theme.accentSecondary
                }
                onClicked: translateRequested(langSelector.sourceLang)
            }

            Button {
                id: acceptBtn
                text: "✓ Accept"
                enabled: translationController.status === "TRANSLATED" || translationController.status === "EDITED" || translationController.status === "ACCEPTED"
                font.family: Theme.fontUI
                font.pixelSize: Theme.fontSizeBody
                font.bold: true
                
                contentItem: Text {
                    text: acceptBtn.text; font: acceptBtn.font
                    color: !acceptBtn.enabled ? Theme.textDisabled : Theme.bgApp
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    implicitWidth: 100; implicitHeight: 32; radius: Theme.radius
                    color: !acceptBtn.enabled ? Theme.bgSurfaceSoft : Theme.accentPrimary
                }
                onClicked: acceptRequested(translationInput.text)
            }
        }
    }
}