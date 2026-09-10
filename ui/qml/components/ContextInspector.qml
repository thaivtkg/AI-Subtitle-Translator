import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

ColumnLayout {
    id: inspectorRoot
    spacing: Theme.spaceMedium

    // --- 1. STORY SUMMARY (Muted Surface / Editable) ---
    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: 20
        spacing: Theme.spaceXs

        Text {
            text: "STORY SUMMARY"
            color: Theme.textSecondary
            font.pixelSize: 12
            font.bold: true
            Layout.leftMargin: Theme.spaceXs
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.bgSurface
            radius: Theme.radius
            border.color: summaryInput.activeFocus ? Theme.accentCyan : Theme.border
            border.width: 1
            Behavior on border.color { ColorAnimation { duration: 100 } }

            ScrollView {
                anchors.fill: parent
                anchors.margins: Theme.spaceSmall
                TextArea {
                    id: summaryInput
                    text: globalStorySummary
                    placeholderText: "Nhập quy tắc dịch, bối cảnh, xưng hô..."
                    color: Theme.textPrimary
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                    background: null
                    selectByMouse: true
                    Keys.onPressed: function(event) {
                        if (event.key !== Qt.Key_Tab) return

                        const nextItem = summaryInput.nextItemInFocusChain(!(event.modifiers & Qt.ShiftModifier))
                        if (nextItem) {
                            nextItem.forceActiveFocus(Qt.TabFocusReason)
                            event.accepted = true
                        }
                    }
                    onTextChanged: {
                        globalStorySummary = text
                        if (typeof projectController !== "undefined") projectController.markDirty()
                    }
                }
            }
        }
    }

    // --- 2. PREVIOUS CONTEXT (Muted Surface / Read-only) ---
    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: 20
        spacing: Theme.spaceXs

        Text {
            text: "PREVIOUS"
            color: Theme.textSecondary
            font.pixelSize: 12
            font.bold: true
            Layout.leftMargin: Theme.spaceXs
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.bgSurface
            radius: Theme.radius
            border.color: Theme.border
            border.width: 1

            ScrollView {
                anchors.fill: parent
                anchors.margins: Theme.spaceSmall
                Text {
                    text: translationController.contextPrev || "No previous context"
                    color: translationController.contextPrev ? Theme.textSecondary : Theme.textDisabled
                    font.pixelSize: 13
                    wrapMode: Text.WordWrap
                    lineHeight: 1.3
                }
            }
        }
    }

    // --- 3. CURRENT HIGHLIGHT (Elevated Surface / Hero Context) ---
    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: 35
        spacing: Theme.spaceXs

        Text {
            text: "◆ CURRENT"
            color: Theme.accentCyan
            font.pixelSize: 12
            font.bold: true
            Layout.leftMargin: Theme.spaceXs
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.bgSurfaceElevated
            radius: Theme.radius
            border.color: Theme.accentCyan
            border.width: 1

            ScrollView {
                anchors.fill: parent
                anchors.margins: Theme.spaceMedium
                Text {
                    text: translationController.currentOriginal || "No subtitle selected"
                    color: translationController.currentOriginal ? Theme.textPrimary : Theme.textDisabled
                    font.pixelSize: 15
                    wrapMode: Text.WordWrap
                    font.bold: translationController.currentOriginal !== ""
                    lineHeight: 1.3
                }
            }
        }
    }

    // --- 4. NEXT CONTEXT (Disabled text / Read-only) ---
    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: 25
        spacing: Theme.spaceXs

        Text {
            text: "NEXT"
            color: Theme.textSecondary
            font.pixelSize: 12
            font.bold: true
            Layout.leftMargin: Theme.spaceXs
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.bgSurface
            radius: Theme.radius
            border.color: Theme.border
            border.width: 1

            ScrollView {
                anchors.fill: parent
                anchors.margins: Theme.spaceSmall
                Text {
                    text: translationController.contextNext || "No next context"
                    color: translationController.contextNext ? Theme.textSecondary : Theme.textDisabled
                    font.pixelSize: 13
                    wrapMode: Text.WordWrap
                    lineHeight: 1.3
                }
            }
        }
    }
}
