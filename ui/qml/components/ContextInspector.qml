import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

ColumnLayout {
    id: inspectorRoot
    spacing: 12
    
    // TAB BAR CAPSULE
    Rectangle {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        implicitHeight: 38
        radius: 14
        color: Qt.rgba(1.0, 1.0, 1.0, 0.10)
        border.color: Theme.glassBorderSpecularLower
        border.width: 1

        TabBar {
            id: contextTabs
            objectName: "contextTabs"
            anchors.fill: parent
            anchors.margins: 3
            spacing: 4
            background: Item {}
            
            TabButton {
                id: tabTimeline
                text: "TIMELINE"
                width: Math.floor(contextTabs.width / 3)
                contentItem: Text {
                    text: parent.text
                    font.pixelSize: 11
                    font.bold: true
                    color: parent.checked ? "#FFFFFF" : Theme.textSecondary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                background: Rectangle {
                    radius: 10
                    color: parent.checked ? Theme.accentSapphire : "transparent"
                    border.color: parent.checked ? Theme.glassBorderSpecularUpper : "transparent"
                    border.width: parent.checked ? 1 : 0
                    
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        radius: parent.radius
                        color: Qt.rgba(1.0, 1.0, 1.0, 0.4)
                        visible: parent.parent.checked
                    }

                    Behavior on color { ColorAnimation { duration: Theme.animHover } }
                }
            }

            TabButton {
                id: tabIntelligence
                text: "INTELLIGENCE"
                width: Math.floor(contextTabs.width / 3)
                contentItem: Text {
                    text: parent.text
                    font.pixelSize: 11
                    font.bold: true
                    color: parent.checked ? "#FFFFFF" : Theme.textSecondary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                background: Rectangle {
                    radius: 10
                    color: parent.checked ? Theme.accentSapphire : "transparent"
                    border.color: parent.checked ? Theme.glassBorderSpecularUpper : "transparent"
                    border.width: parent.checked ? 1 : 0
                    
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        radius: parent.radius
                        color: Qt.rgba(1.0, 1.0, 1.0, 0.4)
                        visible: parent.parent.checked
                    }

                    Behavior on color { ColorAnimation { duration: Theme.animHover } }
                }
            }

            TabButton {
                id: tabSummary
                text: "SUMMARY"
                width: Math.floor(contextTabs.width / 3)
                contentItem: Text {
                    text: parent.text
                    font.pixelSize: 11
                    font.bold: true
                    color: parent.checked ? "#FFFFFF" : Theme.textSecondary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                background: Rectangle {
                    radius: 10
                    color: parent.checked ? Theme.accentSapphire : "transparent"
                    border.color: parent.checked ? Theme.glassBorderSpecularUpper : "transparent"
                    border.width: parent.checked ? 1 : 0
                    
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        radius: parent.radius
                        color: Qt.rgba(1.0, 1.0, 1.0, 0.4)
                        visible: parent.parent.checked
                    }

                    Behavior on color { ColorAnimation { duration: Theme.animHover } }
                }
            }
        }
    }
    
    StackLayout {
        currentIndex: contextTabs.currentIndex
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: 4
        
        // TAB 1: TIMELINE
        ColumnLayout {
            spacing: 12
            
            // --- PREV CONTEXT POD ---
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: prevCol.implicitHeight + 24
                radius: 16
                color: Theme.glassPodLuminous
                border.color: Theme.glassBorderSpecularUpper
                border.width: 1.5

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    radius: parent.radius
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.65)
                }

                ColumnLayout {
                    id: prevCol
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6
                    
                    RowLayout {
                        Layout.fillWidth: true
                        Rectangle {
                            implicitWidth: prevBadgeText.implicitWidth + 14
                            implicitHeight: 18
                            radius: 9
                            color: Qt.rgba(0.0, 0.4, 1.0, 0.12)
                            border.color: Qt.rgba(0.0, 0.4, 1.0, 0.25)
                            border.width: 1

                            Text {
                                id: prevBadgeText
                                anchors.centerIn: parent
                                text: "CÂU TRƯỚC (PREV)"
                                color: "#0369A1"
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 0.5
                            }
                        }
                        Item { Layout.fillWidth: true }
                    }

                    Text {
                        text: translationController.contextPrev !== "" ? translationController.contextPrev : "Không có ngữ cảnh trước."
                        color: translationController.contextPrev !== "" ? Theme.textOnLightPod : "#64748B"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }
                }
            }
            
            // Current Subtitle Marker Divider
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.25)
                }

                Rectangle {
                    implicitWidth: currentMarkerText.implicitWidth + 16
                    implicitHeight: 20
                    radius: 10
                    color: Qt.rgba(0.0, 0.4, 1.0, 0.18)
                    border.color: Qt.rgba(0.0, 0.4, 1.0, 0.4)
                    border.width: 1

                    Text {
                        id: currentMarkerText
                        anchors.centerIn: parent
                        text: "⭐ ĐANG XEM"
                        color: Theme.accentSapphire
                        font.pixelSize: 10
                        font.bold: true
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.25)
                }
            }
            
            // --- NEXT CONTEXT POD ---
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: nextCol.implicitHeight + 24
                radius: 16
                color: Theme.glassPodLuminous
                border.color: Theme.glassBorderSpecularUpper
                border.width: 1.5

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    radius: parent.radius
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.65)
                }

                ColumnLayout {
                    id: nextCol
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6
                    
                    RowLayout {
                        Layout.fillWidth: true
                        Rectangle {
                            implicitWidth: nextBadgeText.implicitWidth + 14
                            implicitHeight: 18
                            radius: 9
                            color: Qt.rgba(0.0, 0.4, 1.0, 0.12)
                            border.color: Qt.rgba(0.0, 0.4, 1.0, 0.25)
                            border.width: 1

                            Text {
                                id: nextBadgeText
                                anchors.centerIn: parent
                                text: "CÂU TIẾP THEO (NEXT)"
                                color: "#0369A1"
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 0.5
                            }
                        }
                        Item { Layout.fillWidth: true }
                    }

                    Text {
                        text: translationController.contextNext !== "" ? translationController.contextNext : "Không có ngữ cảnh sau."
                        color: translationController.contextNext !== "" ? Theme.textOnLightPod : "#64748B"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
        
        // TAB 2: INTELLIGENCE
        ColumnLayout {
            spacing: 12
            
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: intelCol.implicitHeight + 28
                radius: 16
                color: Theme.glassPodLuminous
                border.color: Theme.glassBorderSpecularUpper
                border.width: 1.5

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    radius: parent.radius
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.65)
                }

                ColumnLayout {
                    id: intelCol
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    RowLayout {
                        Rectangle {
                            implicitWidth: intelBadge.implicitWidth + 14
                            implicitHeight: 20
                            radius: 10
                            color: Theme.accentSapphire

                            Text {
                                id: intelBadge
                                anchors.centerIn: parent
                                text: "🧠 AI INTELLIGENCE & GLOSSARY"
                                color: "#FFFFFF"
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }
                        Item { Layout.fillWidth: true }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: "Không tìm thấy thuật ngữ (Glossary) hoặc bộ nhớ dịch (TM) khớp với câu này."
                        color: "#475569"
                        font.pixelSize: 12
                        font.bold: true
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: tipRow.implicitHeight + 12
                        radius: 8
                        color: Theme.glassPodRaised
                        border.color: Theme.glassBorderSpecularLower
                        border.width: 1

                        RowLayout {
                            id: tipRow
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6
                            Text { text: "💡"; font.pixelSize: 12 }
                            Text {
                                Layout.fillWidth: true
                                text: "Hệ thống sẽ tự động đối chiếu từ khóa khi có Glossary trong dự án."
                                color: Theme.textOnLightPod
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
        
        // TAB 3: SUMMARY
        ColumnLayout {
            spacing: 8
            
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.glassPodRaised
                radius: 16
                border.color: summaryInput.activeFocus ? Theme.accentSapphire : Theme.glassBorderSpecularUpper
                border.width: summaryInput.activeFocus ? 2 : 1.5

                Behavior on border.color { ColorAnimation { duration: Theme.animFocus } }

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    radius: parent.radius
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.70)
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Rectangle {
                            implicitWidth: summaryBadge.implicitWidth + 14
                            implicitHeight: 20
                            radius: 10
                            color: Theme.accentSapphire

                            Text {
                                id: summaryBadge
                                anchors.centerIn: parent
                                text: "TỔNG QUAN & BỐI CẢNH DỰ ÁN"
                                color: "#FFFFFF"
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 0.5
                            }
                        }
                        Item { Layout.fillWidth: true }
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        TextArea {
                            objectName: "storySummaryInput"
                            id: summaryInput
                            text: typeof globalStorySummary !== "undefined" ? globalStorySummary : ""
                            placeholderText: "Nhập quy tắc dịch, bối cảnh, xưng hô..."
                            placeholderTextColor: "#94A3B8"
                            color: Theme.textOnLightPod
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            wrapMode: Text.WordWrap
                            background: null
                            selectByMouse: true
                            selectionColor: Theme.accentSapphire
                            selectedTextColor: "#FFFFFF"
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
}
