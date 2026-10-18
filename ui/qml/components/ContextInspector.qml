import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

ColumnLayout {
    id: inspectorRoot
    spacing: 8

    // HEADER CỘT PHẢI: THANH NGỮ CẢNH + SUBTITLE + HOT-L & ĐÓNG (MATCHING DESIGN)
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "🟣 THANH NGỮ CẢNH (INSPECTOR)"
                color: "#FFFFFF"
                font.pixelSize: 13
                font.bold: true
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.16)
                border.color: Qt.rgba(1, 1, 1, 0.3)
                border.width: 1
                implicitWidth: closeLbl.implicitWidth + 14
                implicitHeight: 24
                Text {
                    id: closeLbl
                    anchors.centerIn: parent
                    text: "Hot-L & Đóng"
                    color: "#FFFFFF"
                    font.pixelSize: 11
                }
            }
        }

        Text {
            text: "⚡ Bấm đúp để sửa nhanh Mốc Giờ & Ràng Buộc ⚙"
            color: Qt.rgba(1, 1, 1, 0.75)
            font.pixelSize: 11
        }
    }

    // Đường kẻ ngang phân cách dưới tiêu đề cột
    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Qt.rgba(1, 1, 1, 0.20)
    }

    // TAB BAR CAPSULE WITH HOLD & DRAG SLIDING PILL (D:\dichuyen.mp4)
    Rectangle {
        id: tabOuterContainer
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        implicitHeight: 38
        radius: 14
        color: Qt.rgba(1.0, 1.0, 1.0, 0.16)
        border.color: Theme.glassBorderSpecularLower
        border.width: 1

        readonly property int tabCount: 3
        readonly property real tabWidth: Math.floor((tabOuterContainer.width - 6) / tabCount)
        property bool isDragging: false
        property real pillDragX: 0

        // SLIDING LIQUID PILL (D:\dichuyen.mp4)
        Rectangle {
            id: slidingPill
            y: 3
            width: tabOuterContainer.tabWidth
            height: tabOuterContainer.height - 6
            radius: 10
            color: Theme.accentSapphire
            border.color: Theme.glassBorderSpecularUpper
            border.width: 1
            z: 1

            x: tabOuterContainer.isDragging
               ? tabOuterContainer.pillDragX
               : (3 + contextTabs.currentIndex * tabOuterContainer.tabWidth)

            scale: tabOuterContainer.isDragging ? 0.95 : 1.0
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

            Behavior on x {
                enabled: !tabOuterContainer.isDragging
                NumberAnimation {
                    duration: 280
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.25
                }
            }

            // Top specular highlight
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                radius: parent.radius
                color: Qt.rgba(1.0, 1.0, 1.0, 0.45)
            }
        }

        TabBar {
            id: contextTabs
            objectName: "contextTabs"
            anchors.fill: parent
            anchors.margins: 3
            spacing: 0
            implicitWidth: tabOuterContainer.width
            background: Item {}
            z: 2

            TabButton {
                id: tabTimeline
                text: "TIMELINE"
                implicitWidth: tabOuterContainer.tabWidth
                contentItem: Text {
                    text: parent.text
                    font.pixelSize: 11
                    font.bold: true
                    color: contextTabs.currentIndex === 0 ? "#FFFFFF" : Theme.textSecondary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                background: Item {}
            }

            TabButton {
                id: tabIntelligence
                text: "INTELLIGENCE"
                implicitWidth: tabOuterContainer.tabWidth
                contentItem: Text {
                    text: parent.text
                    font.pixelSize: 11
                    font.bold: true
                    color: contextTabs.currentIndex === 1 ? "#FFFFFF" : Theme.textSecondary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                background: Item {}
            }

            TabButton {
                id: tabSummary
                text: "SUMMARY"
                implicitWidth: tabOuterContainer.tabWidth
                contentItem: Text {
                    text: parent.text
                    font.pixelSize: 11
                    font.bold: true
                    color: contextTabs.currentIndex === 2 ? "#FFFFFF" : Theme.textSecondary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                background: Item {}
            }
        }

        // MOUSE AREA FOR PRESS-AND-HOLD & HORIZONTAL DRAG PHYSICS (D:\dichuyen.mp4)
        MouseArea {
            id: tabDragArea
            anchors.fill: parent
            z: 3
            hoverEnabled: true
            cursorShape: tabOuterContainer.isDragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton

            property real startMouseX: 0
            property real initialPillX: 0
            property bool hasMoved: false

            onPressed: function(mouse) {
                startMouseX = mouse.x
                initialPillX = slidingPill.x
                tabOuterContainer.pillDragX = initialPillX
                hasMoved = false
            }

            onPositionChanged: function(mouse) {
                if (pressed) {
                    var dx = mouse.x - startMouseX
                    if (!tabOuterContainer.isDragging && Math.abs(dx) > 4) {
                        tabOuterContainer.isDragging = true
                    }
                    if (tabOuterContainer.isDragging) {
                        hasMoved = true
                        var minX = 3
                        var maxX = tabOuterContainer.width - 3 - tabOuterContainer.tabWidth
                        var rawX = initialPillX + dx
                        if (rawX < minX) rawX = minX - (minX - rawX) * 0.3
                        else if (rawX > maxX) rawX = maxX + (rawX - maxX) * 0.3
                        tabOuterContainer.pillDragX = rawX
                    }
                }
            }

            onReleased: function(mouse) {
                if (tabOuterContainer.isDragging) {
                    tabOuterContainer.isDragging = false
                    var pillCenter = tabOuterContainer.pillDragX + tabOuterContainer.tabWidth / 2
                    var targetIndex = Math.floor((pillCenter - 3) / tabOuterContainer.tabWidth)
                    targetIndex = Math.max(0, Math.min(tabOuterContainer.tabCount - 1, targetIndex))
                    contextTabs.currentIndex = targetIndex
                } else if (!hasMoved) {
                    var clickIndex = Math.floor((mouse.x - 3) / tabOuterContainer.tabWidth)
                    clickIndex = Math.max(0, Math.min(tabOuterContainer.tabCount - 1, clickIndex))
                    contextTabs.currentIndex = clickIndex
                }
            }
        }
    }
    
    StackLayout {
        currentIndex: contextTabs.currentIndex
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: 4
        
        // TAB 1: TIMELINE (100% MATCHING DESIGN MOCKUP)
        ColumnLayout {
            spacing: 12

            // CARD 1: THỜI LƯỢNG & TỐC ĐỘ
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: timingCol.implicitHeight + 24
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
                    id: timingCol
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "⏱️ THỜI LƯỢNG & TỐC ĐỘ"
                            color: "#0284C7"
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 0.5
                        }
                        Item { Layout.fillWidth: true }
                    }

                    Text {
                        text: (typeof translationController !== "undefined" && translationController.currentStartTime !== ""
                               ? (translationController.currentStartTime + " ➔ " + translationController.currentEndTime)
                               : "00:01:14.200 ➔ 00:01:17.800")
                        color: "#0F172A"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Text {
                        text: "Thời lượng: 3.60s • Tốc độ: 14 ký tự/giây"
                        color: "#475569"
                        font.pixelSize: 11
                    }
                }
            }

            // CARD 2: KIỂM TRA QUY CHUẨN (QA)
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: qaCol.implicitHeight + 24
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
                    id: qaCol
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "✓ KIỂM TRA QUY CHUẨN (QA)"
                            color: "#16A34A"
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 0.5
                        }
                        Item { Layout.fillWidth: true }
                    }

                    Text {
                        text: "Không vượt giới hạn 37 ký tự/dòng"
                        color: "#0F172A"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Text {
                        text: "CPS tối ưu (Chuẩn Netflix/YouTube)"
                        color: "#15803D"
                        font.pixelSize: 11
                        font.bold: true
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
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 130
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
                            color: "#AD1457"

                            Text {
                                id: summaryBadge
                                anchors.centerIn: parent
                                text: "📌 TÓM TẮT CỐT TRUYỆN"
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

            // Đẩy thẻ Summary lên trên, giữ khoảng trống kính mờ bên dưới
            Item { Layout.fillHeight: true }
        }
    }
}
