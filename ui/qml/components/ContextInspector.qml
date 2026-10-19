import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import "../theme"

ColumnLayout {
    id: inspectorRoot
    spacing: 8

    function switchToTab(idx) {
        if (contextTabs) {
            contextTabs.setCurrentIndex(idx)
        }
    }

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

        Behavior on fluidScaleX { enabled: !tabSquashImpulse.running; NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
        Behavior on fluidScaleY { enabled: !tabSquashImpulse.running; NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

        // Bắt sự kiện đổi tab (do Click hoặc gọi lệnh)
        Connections {
            target: contextTabs
            function onCurrentIndexChanged() {
                if (!tabOuterContainer.isDragging) {
                    tabSquashImpulse.restart()
                }
            }
        }

        // Chuỗi xung lực biến dạng giọt nước: Phóng dãn -> Đập dẹt -> Nảy về ban đầu
        SequentialAnimation {
            id: tabSquashImpulse
            ParallelAnimation {
                NumberAnimation { target: tabOuterContainer; property: "fluidScaleX"; to: 1.15; duration: 90; easing.type: Easing.OutQuad }
                NumberAnimation { target: tabOuterContainer; property: "fluidScaleY"; to: 0.88; duration: 90; easing.type: Easing.OutQuad }
            }
            ParallelAnimation {
                NumberAnimation { target: tabOuterContainer; property: "fluidScaleX"; to: 0.94; duration: 110; easing.type: Easing.InOutQuad }
                NumberAnimation { target: tabOuterContainer; property: "fluidScaleY"; to: 1.04; duration: 110; easing.type: Easing.InOutQuad }
            }
            ParallelAnimation {
                NumberAnimation { target: tabOuterContainer; property: "fluidScaleX"; to: 1.0; duration: 100; easing.type: Easing.OutBack }
                NumberAnimation { target: tabOuterContainer; property: "fluidScaleY"; to: 1.0; duration: 100; easing.type: Easing.OutBack }
            }
        }

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
                    spring: 3.4
                    damping: 0.28
                    epsilon: 0.05
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
        ScrollView {
            id: intelScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                width: intelScroll.availableWidth
                spacing: 12

                // CARD 1: THỂ LOẠI & ĐẠI TỪ
                Rectangle {
                    id: archetypeCard
                    objectName: "archetypeCard"
                    Layout.fillWidth: true
                    implicitHeight: archetypeCardCol.implicitHeight + 24
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
                        id: archetypeCardCol
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        // Header: Title & Status Badge
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: "🎭 BỐI CẢNH & XƯNG HÔ"
                                color: Theme.accentSapphire
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 0.5
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                id: archetypeStatusBadge
                                objectName: "archetypeStatusBadge"
                                implicitWidth: statusBadgeText.implicitWidth + 12
                                implicitHeight: 20
                                radius: 10
                                color: (typeof projectController !== "undefined" && projectController.isArchetypeLocked)
                                       ? Qt.rgba(0.96, 0.62, 0.13, 0.18)
                                       : Qt.rgba(0.09, 0.64, 0.29, 0.18)
                                border.color: (typeof projectController !== "undefined" && projectController.isArchetypeLocked)
                                              ? "#D97706"
                                              : "#16A34A"
                                border.width: 1

                                Text {
                                    id: statusBadgeText
                                    objectName: "statusBadgeText"
                                    anchors.centerIn: parent
                                    text: (typeof projectController !== "undefined" && projectController.isArchetypeLocked)
                                          ? "🔒 Đã khóa"
                                          : "✨ Tự động"
                                    color: (typeof projectController !== "undefined" && projectController.isArchetypeLocked)
                                           ? "#D97706"
                                           : "#16A34A"
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }
                        }

                        // Display active archetype & active pronoun pair
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                id: activeArchetypeDisplay
                                objectName: "activeArchetypeDisplay"
                                text: typeof projectController !== "undefined" ? projectController.archetypeDisplayLabel : "Tự do"
                                color: Theme.textOnLightPod
                                font.pixelSize: 12
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: "•"
                                color: Theme.textOnLightPodMuted
                                font.pixelSize: 11
                            }

                            Text {
                                id: activePronounDisplay
                                objectName: "activePronounDisplay"
                                text: typeof projectController !== "undefined" ? projectController.activePronounPair : "Tự do"
                                color: Theme.accentSapphire
                                font.pixelSize: 12
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Selector ComboBox
                        ComboBox {
                            id: archetypeSelectorCombo
                            objectName: "archetypeSelectorCombo"
                            Layout.fillWidth: true
                            implicitHeight: 32
                            model: typeof projectController !== "undefined" ? projectController.archetypeList : []
                            textRole: "name"

                            leftPadding: 8
                            rightPadding: 24

                            contentItem: RowLayout {
                                spacing: 6

                                Text {
                                    text: {
                                        if (typeof projectController === "undefined") return "🎭"
                                        var list = projectController.archetypeList || []
                                        for (var i = 0; i < list.length; i++) {
                                            if (list[i].id === projectController.activeArchetype) {
                                                return list[i].icon || "🎭"
                                            }
                                        }
                                        return "🎭"
                                    }
                                    font.pixelSize: 12
                                }

                                Text {
                                    text: {
                                        if (typeof projectController === "undefined") return ""
                                        var list = projectController.archetypeList || []
                                        for (var i = 0; i < list.length; i++) {
                                            if (list[i].id === projectController.activeArchetype) {
                                                return list[i].name + " (" + list[i].pronouns + ")"
                                            }
                                        }
                                        return projectController.archetypeDisplayLabel
                                    }
                                    color: Theme.textOnLightPod
                                    font.pixelSize: 11
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            delegate: ItemDelegate {
                                width: archetypeSelectorCombo.width
                                implicitHeight: 32
                                highlighted: typeof projectController !== "undefined" && projectController.activeArchetype === modelData.id
                                contentItem: RowLayout {
                                    spacing: 6
                                    Text {
                                        text: modelData.icon || ""
                                        font.pixelSize: 12
                                    }
                                    Text {
                                        text: modelData.name + " (" + modelData.pronouns + ")"
                                        color: highlighted ? Theme.accentSapphire : Theme.textOnLightPod
                                        font.pixelSize: 11
                                        font.bold: highlighted
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                }
                                background: Rectangle {
                                    color: highlighted ? Qt.rgba(0.0, 0.4, 1.0, 0.12) : (hovered ? Qt.rgba(0, 0, 0, 0.05) : "transparent")
                                }
                            }

                            background: Rectangle {
                                radius: 8
                                color: Qt.rgba(1, 1, 1, 0.75)
                                border.color: Theme.glassBorderSpecularUpper
                                border.width: 1
                            }

                            onActivated: function(index) {
                                if (typeof projectController !== "undefined" && model && model[index]) {
                                    projectController.selectArchetype(model[index].id, true)
                                }
                            }

                            Connections {
                                target: typeof projectController !== "undefined" ? projectController : null
                                function onArchetypeChanged() {
                                    if (typeof projectController === "undefined" || !archetypeSelectorCombo.model) return
                                    for (var i = 0; i < archetypeSelectorCombo.model.length; i++) {
                                        if (archetypeSelectorCombo.model[i].id === projectController.activeArchetype) {
                                            if (archetypeSelectorCombo.currentIndex !== i) {
                                                archetypeSelectorCombo.currentIndex = i
                                            }
                                            break
                                        }
                                    }
                                }
                            }
                        }

                        // Nút "Mở khóa tự động" khi đang khóa thủ công
                        Button {
                            id: btnUnlockArchetype
                            objectName: "btnUnlockArchetype"
                            visible: typeof projectController !== "undefined" && projectController.isArchetypeLocked
                            Layout.fillWidth: true
                            implicitHeight: 28
                            contentItem: Text {
                                text: "🔓 Mở khóa tự động"
                                color: Theme.accentSapphire
                                font.pixelSize: 11
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                radius: 8
                                color: btnUnlockArchetype.hovered ? Qt.rgba(0.0, 0.45, 1.0, 0.15) : Qt.rgba(0.0, 0.45, 1.0, 0.08)
                                border.color: Theme.accentSapphire
                                border.width: 1
                            }
                            onClicked: {
                                if (typeof projectController !== "undefined") {
                                    projectController.selectArchetype(projectController.activeArchetype, false)
                                    if (summaryInput && summaryInput.text.trim().length > 0) {
                                        projectController.analyzeSummary(summaryInput.text)
                                    }
                                }
                            }
                        }
                    }
                }

                // CARD 2: THUẬT NGỮ & THỰC THỂ (EXTRACTED GLOSSARY)
                Rectangle {
                    id: glossaryCard
                    objectName: "glossaryCard"
                    Layout.fillWidth: true
                    implicitHeight: glossaryCardCol.implicitHeight + 24
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
                        id: glossaryCardCol
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        // Title: 📚 THUẬT NGỮ & THỰC THỂ (count)
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                id: glossaryTitleText
                                objectName: "glossaryTitleText"
                                text: "📚 THUẬT NGỮ & THỰC THỂ (" + (typeof projectController !== "undefined" ? projectController.glossaryTerms.length : 0) + ")"
                                color: Theme.accentSapphire
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 0.5
                            }
                            Item { Layout.fillWidth: true }
                        }

                        // Empty state khi chưa có thuật ngữ
                        Rectangle {
                            id: glossaryEmptyState
                            objectName: "glossaryEmptyState"
                            Layout.fillWidth: true
                            implicitHeight: emptyText.implicitHeight + 20
                            radius: 8
                            color: Theme.glassPodRaised
                            border.color: Theme.glassBorderSpecularLower
                            border.width: 1
                            visible: typeof projectController === "undefined" || projectController.glossaryTerms.length === 0

                            Text {
                                id: emptyText
                                anchors.fill: parent
                                anchors.margins: 10
                                text: "Chưa có thuật ngữ nào. Nhập tóm tắt (ví dụ: 'Nhân vật \"Lăng Ba\": Khinh công') ở tab SUMMARY để AI tự động trích xuất sau 2s."
                                color: Theme.textOnLightPodMuted
                                font.pixelSize: 11
                                wrapMode: Text.WordWrap
                            }
                        }

                        // Flow layout hiển thị các chip thuật ngữ
                        Flow {
                            id: termsFlow
                            objectName: "termsFlow"
                            Layout.fillWidth: true
                            width: parent ? parent.width : 260
                            spacing: 6
                            visible: typeof projectController !== "undefined" && projectController.glossaryTerms.length > 0

                            Repeater {
                                id: termsRepeater
                                objectName: "termsRepeater"
                                model: typeof projectController !== "undefined" ? projectController.glossaryTerms : []

                                Rectangle {
                                    id: termChip
                                    objectName: "termChip_" + modelData.source_term
                                    implicitWidth: chipRow.implicitWidth + 16
                                    implicitHeight: 26
                                    radius: 13
                                    color: Theme.glassPodRaised
                                    border.color: modelData.is_auto ? Theme.accentSapphire : Theme.glassBorderSpecularLower
                                    border.width: 1

                                    RowLayout {
                                        id: chipRow
                                        anchors.centerIn: parent
                                        spacing: 6

                                        Rectangle {
                                            implicitWidth: chipBadgeText.implicitWidth + 8
                                            implicitHeight: 16
                                            radius: 8
                                            color: modelData.is_auto ? Theme.accentSapphire : Qt.rgba(0.4, 0.45, 0.55, 0.25)

                                            Text {
                                                id: chipBadgeText
                                                anchors.centerIn: parent
                                                text: modelData.is_auto ? "AI" : "Thủ công"
                                                color: modelData.is_auto ? "#FFFFFF" : Theme.textOnLightPodMuted
                                                font.pixelSize: 9
                                                font.bold: true
                                            }
                                        }

                                        Text {
                                            text: modelData.source_term + " ➔ " + modelData.preferred_translation
                                            color: Theme.textOnLightPod
                                            font.pixelSize: 11
                                            font.bold: true
                                        }

                                        Rectangle {
                                            id: btnDismissTerm
                                            objectName: "btnDismissTerm_" + modelData.source_term
                                            visible: modelData.is_auto
                                            implicitWidth: 16
                                            implicitHeight: 16
                                            radius: 8
                                            color: dismissMouse.containsMouse ? Qt.rgba(0.9, 0.2, 0.2, 0.2) : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "✕"
                                                color: dismissMouse.containsMouse ? "#EF4444" : Theme.textOnLightPodMuted
                                                font.pixelSize: 10
                                                font.bold: true
                                            }

                                            MouseArea {
                                                id: dismissMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (typeof projectController !== "undefined") {
                                                        projectController.dismissAutoTerm(modelData.source_term)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
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
                                summaryDebounceTimer.restart()
                            }
                        }
                    }
                }
            }

            Timer {
                id: summaryDebounceTimer
                objectName: "summaryDebounceTimer"
                interval: 2000
                repeat: false
                onTriggered: {
                    if (typeof projectController !== "undefined" && summaryInput.text.trim().length > 0) {
                        projectController.analyzeSummary(summaryInput.text)
                    }
                }
            }

            // Thanh capsule thông tin nhỏ
            Rectangle {
                id: summaryArchetypeCapsule
                objectName: "summaryArchetypeCapsule"
                Layout.fillWidth: true
                implicitHeight: summaryCapsuleCol.implicitHeight + 16
                radius: 12
                color: Theme.glassPodRaised
                border.color: Theme.glassBorderSpecularLower
                border.width: 1
                visible: typeof projectController !== "undefined"

                ColumnLayout {
                    id: summaryCapsuleCol
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            id: summaryCapsuleIcon
                            text: {
                                if (typeof projectController === "undefined") return "🎭"
                                var list = projectController.archetypeList || []
                                for (var i = 0; i < list.length; i++) {
                                    if (list[i].id === projectController.activeArchetype) {
                                        return list[i].icon || "🎭"
                                    }
                                }
                                return "🎭"
                            }
                            font.pixelSize: 13
                        }

                        Text {
                            id: summaryCapsuleLabel
                            objectName: "summaryCapsuleLabel"
                            text: typeof projectController !== "undefined" ? projectController.archetypeDisplayLabel : "Tự do"
                            color: Theme.textOnLightPod
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            id: summaryCapsulePronouns
                            objectName: "summaryCapsulePronouns"
                            text: typeof projectController !== "undefined" ? projectController.activePronounPair : ""
                            color: Theme.accentSapphire
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    Text {
                        id: summaryCapsuleStatus
                        objectName: "summaryCapsuleStatus"
                        text: typeof projectController !== "undefined" && projectController.isArchetypeLocked
                              ? "🔒 Đã khóa thủ công"
                              : "✨ Tự động nhận diện sau 2s"
                        color: typeof projectController !== "undefined" && projectController.isArchetypeLocked
                               ? "#D97706"
                               : "#16A34A"
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
            }

            // Nút bấm tương tác: Đánh dấu phụ đề dịch từ tiếng Nhật (BẬT / TẮT)
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 28
                radius: 14
                color: (typeof projectController !== "undefined" && projectController.isJaOrigin)
                       ? Qt.rgba(0.96, 0.45, 0.71, 0.15) 
                       : Qt.rgba(0.58, 0.64, 0.72, 0.12)
                border.color: (typeof projectController !== "undefined" && projectController.isJaOrigin)
                             ? "#F472B6" 
                             : "#94A3B8"
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: (typeof projectController !== "undefined" && projectController.isJaOrigin) ? "🌸" : "🌐"
                        font.pixelSize: 11
                    }

                    Text {
                        text: (typeof projectController !== "undefined" && projectController.isJaOrigin)
                              ? "Nguồn gốc: Dịch từ tiếng Nhật ('senior' ➔ 'tiền bối')"
                              : "Nguồn gốc: Tiếng Anh bản ngữ ('senior' dịch tự nhiên)"
                        color: (typeof projectController !== "undefined" && projectController.isJaOrigin) ? "#BE185D" : "#475569"
                        font.pixelSize: 10
                        font.bold: true
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof projectController !== "undefined") {
                            projectController.setIsJaOrigin(!projectController.isJaOrigin)
                        }
                    }
                }
            }

            // Đẩy thẻ Summary lên trên, giữ khoảng trống kính mờ bên dưới
            Item { Layout.fillHeight: true }
        }
    }
}
