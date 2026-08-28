import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

ColumnLayout {
    id: inspectorRoot
    spacing: Theme.space12 // Tạo khoảng cách giữa các thẻ

    // --- 1. STORY SUMMARY CARD (20%) ---
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: inspectorRoot.height * 0.2
        color: Theme.bgApp // Dùng màu chìm hơn so với nền panel
        radius: 6

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.space12
            spacing: Theme.space4
            
            Text { 
                text: "STORY SUMMARY"
                color: Theme.textSecondary
                font.family: Theme.fontUI
                font.pixelSize: Theme.fontCaption
                font.bold: true 
            }
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                TextArea { 
                    text: globalStorySummary
                    placeholderText: "Nhập quy tắc dịch, bối cảnh..."
                    color: Theme.accentSecondary
                    font.family: Theme.fontUI
                    font.pixelSize: Theme.fontBody
                    wrapMode: Text.WordWrap
                    background: null
                    topPadding: 0; leftPadding: 0; rightPadding: 0
                    onTextChanged: globalStorySummary = text 
                }
            }
        }
    }

    // --- 2. PREVIOUS CONTEXT CARD (20%) ---
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: inspectorRoot.height * 0.2
        color: Theme.bgApp
        radius: 6

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.space12
            spacing: Theme.space4
            
            Text { 
                text: "PREVIOUS"
                color: Theme.textSecondary
                font.family: Theme.fontUI
                font.pixelSize: Theme.fontCaption
                font.bold: true 
            }
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Text { 
                    text: translationController.contextPrev
                    color: Theme.textSecondary
                    font.family: Theme.fontUI
                    font.pixelSize: Theme.fontBody
                    wrapMode: Text.WordWrap
                    lineHeight: 1.3 
                }
            }
        }
    }

    // --- 3. CURRENT HIGHLIGHT CARD (35% - HERO CARD) ---
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: inspectorRoot.height * 0.35
        color: Theme.bgSurfaceElevated // Nổi hẳn lên khỏi nền
        radius: 6
        border.color: Theme.accentSecondary
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.space12
            spacing: Theme.space4
            
            Text { 
                text: "◆ CURRENT"
                color: Theme.accentSecondary
                font.family: Theme.fontUI
                font.pixelSize: Theme.fontCaption
                font.bold: true 
            }
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Text { 
                    text: translationController.currentOriginal
                    color: Theme.textPrimary
                    font.family: Theme.fontUI
                    font.pixelSize: Theme.fontBody
                    wrapMode: Text.WordWrap
                    font.bold: true 
                    lineHeight: 1.3
                }
            }
        }
    }

    // --- 4. NEXT CONTEXT CARD (25%) ---
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: inspectorRoot.height * 0.25
        color: Theme.bgApp
        radius: 6

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.space12
            spacing: Theme.space4
            
            Text { 
                text: "NEXT"
                color: Theme.textSecondary
                font.family: Theme.fontUI
                font.pixelSize: Theme.fontCaption
                font.bold: true 
            }
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Text { 
                    text: translationController.contextNext
                    color: Theme.textDisabled
                    font.family: Theme.fontUI
                    font.pixelSize: Theme.fontBody
                    wrapMode: Text.WordWrap
                    lineHeight: 1.3 
                }
            }
        }
    }
}