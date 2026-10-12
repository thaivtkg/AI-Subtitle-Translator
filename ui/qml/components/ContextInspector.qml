import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

ColumnLayout {
    id: inspectorRoot
    spacing: 0
    
    // TAB BAR
    TabBar {
        id: contextTabs
        objectName: "contextTabs"
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        implicitWidth: 0
        background: Rectangle { 
            color: "transparent"
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border } 
        }
        
        TabButton {
            text: "TIMELINE"
            width: Math.floor(contextTabs.width / 3)
            contentItem: Text {
                text: parent.text
                font.pixelSize: 11
                font.bold: parent.checked
                color: parent.checked ? Theme.accentCyan : Theme.textSecondary
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            background: Rectangle {
                color: "transparent"
                Rectangle {
                    width: parent.width
                    height: 2
                    anchors.bottom: parent.bottom
                    color: parent.parent.checked ? Theme.accentCyan : "transparent"
                }
            }
        }
        TabButton {
            text: "INTELLIGENCE"
            width: Math.floor(contextTabs.width / 3)
            contentItem: Text {
                text: parent.text
                font.pixelSize: 11
                font.bold: parent.checked
                color: parent.checked ? Theme.accentCyan : Theme.textSecondary
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            background: Rectangle {
                color: "transparent"
                Rectangle {
                    width: parent.width
                    height: 2
                    anchors.bottom: parent.bottom
                    color: parent.parent.checked ? Theme.accentCyan : "transparent"
                }
            }
        }
        TabButton {
            text: "SUMMARY"
            width: Math.floor(contextTabs.width / 3)
            contentItem: Text {
                text: parent.text
                font.pixelSize: 11
                font.bold: parent.checked
                color: parent.checked ? Theme.accentCyan : Theme.textSecondary
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            background: Rectangle {
                color: "transparent"
                Rectangle {
                    width: parent.width
                    height: 2
                    anchors.bottom: parent.bottom
                    color: parent.parent.checked ? Theme.accentCyan : "transparent"
                }
            }
        }
    }
    
    StackLayout {
        currentIndex: contextTabs.currentIndex
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: Theme.spaceMedium
        
        // TAB 1: TIMELINE
        ColumnLayout {
            spacing: Theme.spaceMedium
            
            // --- PREV CONTEXT ---
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spaceXs
                
                Text {
                    text: "CÂU TRƯỚC"
                    color: Theme.textMuted
                    font.pixelSize: 11
                    font.bold: true
                }
                Text {
                    text: translationController.contextPrev !== "" ? translationController.contextPrev : "Không có ngữ cảnh trước."
                    color: Theme.textSecondary
                    font.pixelSize: 13
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                }
            }
            
            // Current marker
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
            }
            
            // --- NEXT CONTEXT ---
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spaceXs
                
                Text {
                    text: "CÂU TIẾP THEO"
                    color: Theme.textMuted
                    font.pixelSize: 11
                    font.bold: true
                }
                Text {
                    text: translationController.contextNext !== "" ? translationController.contextNext : "Không có ngữ cảnh sau."
                    color: Theme.textSecondary
                    font.pixelSize: 13
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                }
            }
            Item { Layout.fillHeight: true }
        }
        
        // TAB 2: INTELLIGENCE
        ColumnLayout {
            spacing: Theme.spaceMedium
            
            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.alignment: Qt.AlignHCenter
                text: "Không tìm thấy thuật ngữ (Glossary) hoặc bộ nhớ dịch (TM) khớp với câu này."
                color: Theme.textMuted
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
            Item { Layout.fillHeight: true }
        }
        
        // TAB 3: SUMMARY
        ColumnLayout {
            spacing: Theme.spaceSmall
            
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.bgSurface
                radius: Theme.radius
                border.color: summaryInput.activeFocus ? Theme.accentCyan : Theme.border
                border.width: 1
                
                ScrollView {
                    anchors.fill: parent
                    anchors.margins: Theme.spaceSmall
                    TextArea {
                        objectName: "storySummaryInput"
                        id: summaryInput
                        text: typeof globalStorySummary !== "undefined" ? globalStorySummary : ""
                        placeholderText: "Nhập quy tắc dịch, bối cảnh, xưng hô..."
                        color: Theme.textPrimary
                        font.pixelSize: 13
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
    }
}
