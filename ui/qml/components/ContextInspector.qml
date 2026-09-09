import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

ColumnLayout {
    id: inspectorRoot
    spacing: Theme.spaceMedium

    // --- 1. STORY SUMMARY CARD (20%) ---
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: inspectorRoot.height * 0.2
        color: Theme.bgApp
        radius: Theme.radius

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spaceMedium
            spacing: Theme.spaceXs

            Text {
                text: "STORY SUMMARY"
                color: Theme.textSecondary
                font.pixelSize: 12
                font.bold: true
            }
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                TextArea {
                    text: globalStorySummary
                    placeholderText: "Nhập quy tắc dịch, bối cảnh..."
                    color: Theme.accentCyan
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                    background: null
                    topPadding: 0
                    leftPadding: 0
                    rightPadding: 0
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
        radius: Theme.radius

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spaceMedium
            spacing: Theme.spaceXs

            Text {
                text: "PREVIOUS"
                color: Theme.textSecondary
                font.pixelSize: 12
                font.bold: true
            }
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Text {
                    text: translationController.contextPrev
                    color: Theme.textSecondary
                    font.pixelSize: 13
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
        color: Theme.bgSurfaceElevated
        radius: Theme.radius
        border.color: Theme.accentCyan
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spaceMedium
            spacing: Theme.spaceXs

            Text {
                text: "◆ CURRENT"
                color: Theme.accentCyan
                font.pixelSize: 12
                font.bold: true
            }
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Text {
                    text: translationController.currentOriginal
                    color: Theme.textPrimary
                    font.pixelSize: 13
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
        radius: Theme.radius

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spaceMedium
            spacing: Theme.spaceXs

            Text {
                text: "NEXT"
                color: Theme.textSecondary
                font.pixelSize: 12
                font.bold: true
            }
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Text {
                    text: translationController.contextNext
                    color: Theme.textDisabled
                    font.pixelSize: 13
                    wrapMode: Text.WordWrap
                    lineHeight: 1.3
                }
            }
        }
    }
}
