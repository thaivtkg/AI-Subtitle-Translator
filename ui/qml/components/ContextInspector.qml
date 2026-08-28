import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

ColumnLayout {
    id: inspectorRoot
    spacing: 0

    // 1. STORY SUMMARY (20%)
    ColumnLayout {
        Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredHeight: inspectorRoot.height * 0.2
        spacing: 0
        
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 32; color: Theme.bgSurface
            Text { text: "STORY SUMMARY"; color: Theme.textSecondary; font.family: Theme.fontUI; font.pixelSize: Theme.fontSizeSmall; font.bold: true; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: Theme.spaceMedium }
        }
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true; color: Theme.bgApp
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
            ScrollView {
                anchors.fill: parent; anchors.margins: Theme.spaceSmall
                TextArea { text: globalStorySummary; placeholderText: "Nhập quy tắc dịch..."; color: Theme.accentSecondary; font.family: Theme.fontUI; font.pixelSize: Theme.fontSizeBody; wrapMode: Text.WordWrap; background: null; onTextChanged: globalStorySummary = text }
            }
        }
    }

    // 2. PREVIOUS CONTEXT (20%)
    ColumnLayout {
        Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredHeight: inspectorRoot.height * 0.2
        spacing: 0
        
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 32; color: Theme.bgSurface
            Text { text: "PREVIOUS"; color: Theme.textSecondary; font.family: Theme.fontUI; font.pixelSize: Theme.fontSizeSmall; font.bold: true; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: Theme.spaceMedium }
        }
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true; color: Theme.bgApp
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
            ScrollView {
                anchors.fill: parent; anchors.margins: Theme.spaceMedium
                Text { text: translationController.contextPrev; color: Theme.textSecondary; font.family: Theme.fontUI; font.pixelSize: Theme.fontSizeBody; wrapMode: Text.WordWrap; lineHeight: 1.3 }
            }
        }
    }

    // 3. CURRENT HIGHLIGHT (30% - Gom chung Header và Body vào 1 khung viền)
    Rectangle {
        Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredHeight: inspectorRoot.height * 0.3
        color: Theme.bgSurfaceElevated
        border.color: Theme.accentSecondary; border.width: 1

        ColumnLayout {
            anchors.fill: parent; spacing: 0
            
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 32; color: "transparent"
                Text { text: "◆ CURRENT"; color: Theme.accentSecondary; font.family: Theme.fontUI; font.pixelSize: Theme.fontSizeSmall; font.bold: true; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: Theme.spaceMedium }
            }
            ScrollView {
                Layout.fillWidth: true; Layout.fillHeight: true; Layout.margins: Theme.spaceMedium; Layout.topMargin: 0
                Text { text: translationController.currentOriginal; color: Theme.textPrimary; font.family: Theme.fontUI; font.pixelSize: Theme.fontSizeBody; wrapMode: Text.WordWrap; font.bold: true }
            }
        }
    }

    // 4. NEXT CONTEXT (30%)
    ColumnLayout {
        Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredHeight: inspectorRoot.height * 0.3
        spacing: 0
        
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 32; color: Theme.bgSurface
            Text { text: "NEXT"; color: Theme.textSecondary; font.family: Theme.fontUI; font.pixelSize: Theme.fontSizeSmall; font.bold: true; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: Theme.spaceMedium }
        }
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true; color: Theme.bgApp
            ScrollView {
                anchors.fill: parent; anchors.margins: Theme.spaceMedium
                Text { text: translationController.contextNext; color: Theme.textDisabled; font.family: Theme.fontUI; font.pixelSize: Theme.fontSizeBody; wrapMode: Text.WordWrap; lineHeight: 1.3 }
            }
        }
    }
}