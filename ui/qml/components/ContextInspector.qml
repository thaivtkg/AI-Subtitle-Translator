import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
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
            Layout.minimumWidth: 0
            spacing: 6

            Text {
                text: "🟣 NGỮ CẢNH"
                color: "#FFFFFF"
                font.pixelSize: 12
                font.bold: true
            }
            Text {
                text: "(INSPECTOR)"
                color: Qt.rgba(1, 1, 1, 0.7)
                font.pixelSize: 11
                visible: inspectorRoot.width >= 310
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.16)
                border.color: Qt.rgba(1, 1, 1, 0.3)
                border.width: 1
                implicitWidth: closeLbl.implicitWidth + 12
                implicitHeight: 22
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

    // TAB BAR CAPSULE WITH HOLD & DRAG SLIDING PILL (E:\Liquid Effect.mp4)
    Rectangle {
        id: tabOuterContainer
        objectName: "tabOuterContainer"
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: Math.min(parent.width - 24, 258)
        Layout.maximumWidth: 265
        implicitHeight: 36
        radius: height / 2 // = 18px
        color: Qt.rgba(1.0, 1.0, 1.0, 0.16)
        border.color: Theme.glassBorderSpecularLower
        border.width: 1

        readonly property int tabCount: 3
        readonly property real baseTabWidth: Math.max(1, (tabOuterContainer.width - 6) / tabCount)
        readonly property real tabWidth: baseTabWidth
        property bool isDragging: false
        property real pillDragX: 0
        property real fluidScaleX: 1.0
        property real fluidScaleY: 1.0
        property real fluidOriginX: baseTabWidth / 2
        readonly property int activeHoverIndex: isDragging
            ? Math.max(0, Math.min(tabCount - 1, Math.floor((pillDragX + baseTabWidth / 2 - 3) / baseTabWidth)))
            : contextTabs.currentIndex

        Behavior on fluidScaleX { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
        Behavior on fluidScaleY { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

        // SLIDING LIQUID PILL (E:\Liquid Effect.mp4)
        Rectangle {
            id: slidingPill
            objectName: "slidingPill"
            y: 3
            height: tabOuterContainer.height - 6 // = 30px
            radius: height / 2 // = 15px (Concentric: 18px - 3px = 15px)

            // Dynamic X and constant width (True 1:1 Sliding Droplet Motion)
            x: tabOuterContainer.isDragging
               ? tabOuterContainer.pillDragX
               : (3 + contextTabs.currentIndex * tabOuterContainer.baseTabWidth)
            width: tabOuterContainer.baseTabWidth

            transform: Scale {
                origin.x: tabOuterContainer.fluidOriginX
                origin.y: slidingPill.height / 2
                xScale: tabOuterContainer.fluidScaleX
                yScale: tabOuterContainer.fluidScaleY
            }

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(0.0, 0.45, 1.0, 0.50) }
                GradientStop { position: 1.0; color: Qt.rgba(0.02, 0.65, 0.98, 0.46) }
            }
            border.color: Qt.rgba(1.0, 1.0, 1.0, 0.85)
            border.width: 1.0
            z: 1

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0.0, 0.15, 0.45, 0.20)
                shadowBlur: 0.35
                shadowVerticalOffset: 2
            }

            Behavior on x {
                enabled: !tabOuterContainer.isDragging
                SpringAnimation {
                    spring: 4.5
                    damping: 0.42
                    epsilon: 0.15
                }
            }
        }

        Item {
            id: contextTabs
            objectName: "contextTabs"
            property int currentIndex: 0
            readonly property int count: 3
            function setCurrentIndex(idx) {
                currentIndex = Math.max(0, Math.min(tabOuterContainer.tabCount - 1, idx))
            }
            anchors.fill: parent
            anchors.margins: 3
            clip: true
            z: 2

            Item {
                id: tabTimeline
                objectName: "tabTimeline"
                x: 0
                width: tabOuterContainer.baseTabWidth
                height: parent.height

                Text {
                    anchors.centerIn: parent
                    text: "TIMELINE"
                    font.pixelSize: 11
                    font.bold: true
                    color: tabOuterContainer.activeHoverIndex === 0 ? "#FFFFFF" : Qt.rgba(1, 1, 1, 0.55)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    Behavior on color { ColorAnimation { duration: 160 } }
                }
            }

            Item {
                id: tabIntelligence
                objectName: "tabIntelligence"
                x: tabOuterContainer.baseTabWidth
                width: tabOuterContainer.baseTabWidth
                height: parent.height

                Text {
                    anchors.centerIn: parent
                    text: "INTELLIGENCE"
                    font.pixelSize: 11
                    font.bold: true
                    color: tabOuterContainer.activeHoverIndex === 1 ? "#FFFFFF" : Qt.rgba(1, 1, 1, 0.55)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    Behavior on color { ColorAnimation { duration: 160 } }
                }
            }

            Item {
                id: tabSummary
                objectName: "tabSummary"
                x: tabOuterContainer.baseTabWidth * 2
                width: tabOuterContainer.baseTabWidth
                height: parent.height

                Text {
                    anchors.centerIn: parent
                    text: "SUMMARY"
                    font.pixelSize: 11
                    font.bold: true
                    color: tabOuterContainer.activeHoverIndex === 2 ? "#FFFFFF" : Qt.rgba(1, 1, 1, 0.55)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    Behavior on color { ColorAnimation { duration: 160 } }
                }
            }
        }

        // MOUSE AREA FOR PRESS-AND-HOLD & HORIZONTAL DRAG PHYSICS (E:\Liquid Effect.mp4)
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
                        var maxX = tabOuterContainer.width - 3 - tabOuterContainer.baseTabWidth
                        var rawX = initialPillX + dx
                        if (rawX < minX) rawX = minX - (minX - rawX) * 0.25
                        else if (rawX > maxX) rawX = maxX + (rawX - maxX) * 0.25
                        tabOuterContainer.pillDragX = rawX

                        tabOuterContainer.fluidScaleX = 1.0 + Math.min(Math.abs(dx) * 0.002, 0.08)
                        tabOuterContainer.fluidScaleY = Math.max(0.94, 1.0 - (tabOuterContainer.fluidScaleX - 1.0) * 0.75)
                    }
                }
            }

            onReleased: function(mouse) {
                if (tabOuterContainer.isDragging) {
                    tabOuterContainer.isDragging = false
                    tabOuterContainer.fluidScaleX = 1.0
                    tabOuterContainer.fluidScaleY = 1.0
                    var pillCenter = tabOuterContainer.pillDragX + tabOuterContainer.baseTabWidth / 2
                    var targetIndex = Math.floor((pillCenter - 3) / tabOuterContainer.baseTabWidth)
                    targetIndex = Math.max(0, Math.min(tabOuterContainer.tabCount - 1, targetIndex))
                    contextTabs.currentIndex = targetIndex
                } else if (!hasMoved) {
                    var clickIndex = Math.floor((mouse.x - 3) / tabOuterContainer.baseTabWidth)
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

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0.08, 0.04, 0.22, 0.14)
                    shadowBlur: 0.4
                    shadowVerticalOffset: 3
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

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0.08, 0.04, 0.22, 0.14)
                    shadowBlur: 0.4
                    shadowVerticalOffset: 3
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
