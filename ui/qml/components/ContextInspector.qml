import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

ColumnLayout {
    spacing: Theme.spaceMedium

    // 1. STORY SUMMARY PANEL
    Text { 
        text: "📖 STORY CONTEXT"
        color: Theme.textPrimary
        font.pixelSize: 12
        font.bold: true 
    }
    
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 180
        color: Theme.bgApp
        border.color: Theme.border
        radius: Theme.radius
        
        ScrollView {
            anchors.fill: parent
            anchors.margins: Theme.spaceSmall
            TextArea {
                text: globalStorySummary // Bind với biến toàn cục
                placeholderText: "Nhập quy tắc dịch, tên nhân vật, quan hệ..."
                color: Theme.accentCyan
                font.pixelSize: 14
                wrapMode: Text.WordWrap
                background: null
                onTextChanged: globalStorySummary = text // Cập nhật ngược lại
            }
        }
    }

    // 2. PREVIOUS CONTEXT
    Text { 
        text: "▲ PREVIOUS SUBTITLES"
        color: Theme.textMuted
        font.pixelSize: 11
        font.bold: true 
        Layout.topMargin: Theme.spaceSmall
    }
    
    Text {
        Layout.fillWidth: true
        text: translationController.contextPrev
        color: Theme.textSecondary
        font.pixelSize: 13
        wrapMode: Text.WordWrap
        lineHeight: 1.2
    }

    // 3. NEXT CONTEXT
    Text { 
        text: "▼ NEXT SUBTITLES"
        color: Theme.textMuted
        font.pixelSize: 11
        font.bold: true 
        Layout.topMargin: Theme.spaceSmall
    }
    
    Text {
        Layout.fillWidth: true
        text: translationController.contextNext
        color: Theme.textDisabled
        font.pixelSize: 13
        wrapMode: Text.WordWrap
        lineHeight: 1.2
    }
    
    // Đẩy nội dung lên trên
    Item { Layout.fillHeight: true } 
}