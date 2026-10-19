import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import "../theme"

Item {
    id: workspace
    
    property bool hasSelection: typeof subtitleModel !== "undefined" && subtitleModel !== null && subtitleModel.rowCount() > 0 && typeof translationController !== "undefined" && translationController.currentOriginal !== ""
    property bool executionLocked: typeof batchController !== "undefined" && batchController.state !== "IDLE" && batchController.state !== "PAUSED" && batchController.state !== "COMPLETED"
    property int totalCount: 0
    property bool compactActions: width < 600
    
    signal translateRequested(string sourceLang)
    signal acceptRequested(string text)
    signal openSrtRequested()
    signal openProjectRequested()
    
    function setSourceLanguage(lang) { langSelector.setLanguage(lang) }
    function getSourceLanguage() { return langSelector.sourceLang }
    
    Rectangle { anchors.fill: parent; color: "transparent" }
    
    EmptyWorkspace {
        anchors.fill: parent
        visible: !workspace.hasSelection
        emptyStateMode: typeof projectController !== "undefined" && projectController.hasProject ? "no_selection" : "no_project"
        onOpenSrtClicked: workspace.openSrtRequested()
        onOpenProjectClicked: workspace.openProjectRequested()
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12
        visible: workspace.hasSelection
        
        // Status & Language Header Row
        RowLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: Theme.spaceSmall
            
            Text {
                text: "⚡ KHÔNG GIAN DỊCH THUẬT" + (typeof subListView !== "undefined" && subListView.currentIndex >= 0 ? (" (CÂU #" + (subListView.currentIndex + 1) + ")") : "")
                color: "#FFFFFF"
                font.pixelSize: 13
                font.bold: true
            }

            // QUAN TRỌNG: Spacer này đẩy Badge trạng thái sang sát mép phải
            Item {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
            }

            Rectangle {
                implicitWidth: statusBadge.implicitWidth + 18
                implicitHeight: 22
                radius: 11
                color: (translationController.status === "ACCEPTED" || translationController.status === "TRANSLATED") ? Theme.badgeSolidEmerald :
                       translationController.status === "ERROR" ? "#FFE4E6" : "#FEF08A"
                border.color: Qt.rgba(1, 1, 1, 0.65)
                border.width: 1.5

                Text {
                    id: statusBadge
                    anchors.centerIn: parent
                    text: (translationController.status === "ACCEPTED" || translationController.status === "TRANSLATED") ? "✓ ĐÃ DỊCH" :
                          translationController.status === "TRANSLATING" ? "⚡ ĐANG DỊCH" :
                          translationController.status === "ERROR" ? "🛑 LỖI" : "⏳ CHỜ DUYỆT"
                    color: (translationController.status === "ACCEPTED" || translationController.status === "TRANSLATED") ? "#FFFFFF" : "#854D0E"
                    font.pixelSize: 10
                    font.bold: true
                }
            }

            LanguageSelector {
                id: langSelector
                objectName: "sourceLangCombo"
                visible: false
                compact: workspace.width < 580
                Layout.alignment: Qt.AlignRight
            }
        }

        
        // Workspace Liquid Glide Container (Elastic transition on subtitle switch)
        Item {
            id: workspaceGlideContainer
            Layout.fillWidth: true
            implicitHeight: glideColumn.implicitHeight
            Layout.preferredHeight: implicitHeight

            property real glideOffset: 0
            property real glideOpacity: 1.0

            Connections {
                target: typeof translationController !== "undefined" ? translationController : null
                function onCurrentOriginalChanged() {
                    glideAnim.restart()
                }
            }

            SequentialAnimation {
                id: glideAnim
                PropertyAction { target: workspaceGlideContainer; property: "glideOffset"; value: 12 }
                PropertyAction { target: workspaceGlideContainer; property: "glideOpacity"; value: 0.35 }
                ParallelAnimation {
                    NumberAnimation {
                        target: workspaceGlideContainer
                        property: "glideOffset"
                        to: 0
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: workspaceGlideContainer
                        property: "glideOpacity"
                        to: 1.0
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Item {
                anchors.fill: parent
                anchors.topMargin: workspaceGlideContainer.glideOffset
                opacity: workspaceGlideContainer.glideOpacity

                ColumnLayout {
                    id: glideColumn
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 12

                    // Original Subtitle Pod
                    Rectangle {
                        id: originalPod
                        Layout.fillWidth: true
                        Layout.preferredHeight: 110
                        Layout.maximumHeight: 110
                        color: Theme.glassPodLuminous
                        radius: 16
                        border.color: Theme.glassBorderSpecularUpper
                        border.width: 1.5

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: Qt.rgba(0.08, 0.04, 0.22, 0.16)
                            shadowBlur: 0.45
                            shadowVerticalOffset: 4
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    implicitWidth: originalBadgeText.implicitWidth + 16
                                    implicitHeight: 20
                                    radius: 10
                                    color: Theme.accentSapphire

                                    Text {
                                        id: originalBadgeText
                                        anchors.centerIn: parent
                                        text: "CÂU GỐC (" + (langSelector.sourceLang ? langSelector.sourceLang.toUpperCase() : "ENGLISH") + ")"
                                        color: "#FFFFFF"
                                        font.pixelSize: 10
                                        font.bold: true
                                        font.letterSpacing: 0.5
                                    }
                                }

                                Rectangle {
                                    visible: typeof translationController.currentStartTime !== "undefined" && translationController.currentStartTime !== ""
                                    implicitWidth: timeRangeText.implicitWidth + 16
                                    implicitHeight: 20
                                    radius: 10
                                    color: Qt.rgba(0.0, 0.4, 1.0, 0.12)
                                    border.color: Qt.rgba(0.0, 0.4, 1.0, 0.3)
                                    border.width: 1

                                    Text {
                                        id: timeRangeText
                                        anchors.centerIn: parent
                                        text: (typeof translationController.currentStartTime !== "undefined" ? translationController.currentStartTime : "") +
                                              " ➔ " +
                                              (typeof translationController.currentEndTime !== "undefined" ? translationController.currentEndTime : "")
                                        color: "#0369A1"
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }

                                Item { Layout.fillWidth: true }
                            }

                            ScrollView {
                                id: origScroll
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                TextArea {
                                    width: origScroll.availableWidth
                                    text: translationController.currentOriginal
                                    color: Theme.textOnLightPod
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                    wrapMode: Text.WordWrap
                                    readOnly: true
                                    background: null
                                    selectByMouse: true
                                    selectionColor: Theme.accentSapphire
                                    selectedTextColor: "#FFFFFF"
                                }
                            }
                        }
                    }

                    // AI Translation Pod
                    Rectangle {
                        id: translationBox
                        Layout.fillWidth: true
                        Layout.preferredHeight: 140
                        Layout.maximumHeight: 140
                        color: Theme.glassPodRaised
                        radius: 16
                        border.color: translationController.status === "TRANSLATING" ? Theme.accentCyan : 
                                      (translationInput.activeFocus ? Theme.accentSapphire : Theme.glassBorderSpecularUpper)
                        border.width: (translationController.status === "TRANSLATING" || translationInput.activeFocus) ? 2 : 1.5
                        clip: true

                        Behavior on border.color { ColorAnimation { duration: Theme.animFocus } }

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: Qt.rgba(0.08, 0.04, 0.22, 0.16)
                            shadowBlur: 0.45
                            shadowVerticalOffset: 4
                        }


                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    implicitWidth: transBadgeText.implicitWidth + 16
                                    implicitHeight: 20
                                    radius: 10
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: Theme.badgePurpleGradientStart }
                                        GradientStop { position: 1.0; color: Theme.badgePurpleGradientEnd }
                                    }

                                    Text {
                                        id: transBadgeText
                                        anchors.centerIn: parent
                                        text: "✨ BẢN DỊCH TIẾNG VIỆT (AI)"
                                        color: "#FFFFFF"
                                        font.pixelSize: 10
                                        font.bold: true
                                        font.letterSpacing: 0.5
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    visible: translationController.status !== "TRANSLATING" && translationInput.text.trim().length > 0
                                    implicitWidth: confText.implicitWidth + 16
                                    implicitHeight: 22
                                    radius: 11
                                    color: "#EDE7F6"
                                    border.color: "#D1C4E9"
                                    border.width: 1

                                    Text {
                                        id: confText
                                        anchors.centerIn: parent
                                        text: "✦ Độ tin cậy: 98%"
                                        color: "#6A1B9A"
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }

                                Rectangle {
                                    visible: translationController.status === "TRANSLATING"
                                    implicitWidth: liveTranslatingRow.implicitWidth + 16
                                    implicitHeight: 20
                                    radius: 10
                                    color: Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.2)
                                    border.color: Theme.accentCyan
                                    border.width: 1

                                    RowLayout {
                                        id: liveTranslatingRow
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Text { text: "⚡"; color: Theme.accentCyan; font.pixelSize: 10 }
                                        Text {
                                            text: "ĐANG DỊCH TRỰC TIẾP"
                                            color: Theme.accentCyan
                                            font.pixelSize: 9
                                            font.bold: true
                                        }
                                    }

                                    SequentialAnimation on opacity {
                                        running: translationController.status === "TRANSLATING"
                                        loops: Animation.Infinite
                                        NumberAnimation { from: 1.0; to: 0.4; duration: 600; easing.type: Easing.InOutQuad }
                                        NumberAnimation { from: 0.4; to: 1.0; duration: 600; easing.type: Easing.InOutQuad }
                                    }
                                }

                                RowLayout {
                                    spacing: 6
                                    visible: translationController.status === "TRANSLATING" || translationInput.text.length > 0

                                    property int wordCount: {
                                        var s = translationInput.text.trim();
                                        return s.length > 0 ? s.split(/\s+/).length : 0;
                                    }

                                    Text {
                                        text: parent.wordCount + " từ"
                                        color: translationController.status === "TRANSLATING" ? Theme.accentCyan : "#475569"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }

                                    Text {
                                        text: "•"
                                        color: "#94A3B8"
                                        font.pixelSize: 10
                                    }

                                    Text {
                                        text: translationInput.text.length + " ký tự"
                                        color: "#475569"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                            }

                            // Translating stream scanner divider
                            Item {
                                id: scannerContainer
                                Layout.fillWidth: true
                                Layout.preferredHeight: 2
                                clip: true
                                opacity: translationController.status === "TRANSLATING" ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 250 } }

                                Rectangle {
                                    anchors.fill: parent
                                    color: Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.12)
                                    radius: 1
                                }

                                Rectangle {
                                    id: streamScanner
                                    height: parent.height
                                    width: Math.max(scannerContainer.width * 0.35, 60)
                                    radius: 1
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: "transparent" }
                                        GradientStop { position: 0.5; color: Theme.accentCyan }
                                        GradientStop { position: 1.0; color: "transparent" }
                                    }

                                    NumberAnimation on x {
                                        from: -streamScanner.width
                                        to: scannerContainer.width > 0 ? scannerContainer.width : 300
                                        duration: 1200
                                        loops: Animation.Infinite
                                        running: translationController.status === "TRANSLATING"
                                    }
                                }
                            }

                            ScrollView {
                                id: transScroll
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true

                                TextArea {
                                    objectName: "translationInput"
                                    id: translationInput
                                    width: transScroll.availableWidth
                                    text: translationController.currentTranslation
                                    placeholderText: translationController.status === "TRANSLATING" ? "" : "Nhập bản dịch tiếng Việt tại đây..."
                                    placeholderTextColor: "#94A3B8"
                                    color: Theme.textOnLightPod
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                    wrapMode: Text.WordWrap
                                    background: null
                                    selectByMouse: true
                                    selectionColor: Theme.accentSapphire
                                    selectedTextColor: "#FFFFFF"
                                    readOnly: translationController.status === "TRANSLATING" || workspace.executionLocked
                                    onTextChanged: {
                                        if (focus && translationController.currentTranslation !== text) {
                                            translationController.updateCurrentTranslation(text)
                                        }
                                    }
                                }
                            }
                        }

                        // Scramble Decoder Overlay
                        Item {
                            id: scrambleOverlay
                            anchors.fill: parent
                            anchors.margins: Theme.spaceMedium
                            visible: translationController.status === "TRANSLATING" && translationInput.text.trim().length === 0
                            z: 5

                            property var phrases: [
                                "ĐANG GIẢI MÃ BỐI CẢNH & PHỤ ĐỀ...",
                                "NEURAL MODEL CONNECTED...",
                                "KHỞI TẠO DÒNG BẢN DỊCH TIẾNG VIỆT...",
                                "TỐI ƯU HÓA ĐỘ DÀI & CPS..."
                            ]
                            property int phraseIndex: 0
                            property string currentTarget: phrases[phraseIndex]
                            property string displayText: ""
                            property real progress: 0.0
                            readonly property string glyphs: "ABCDEFGHJKLMNOPQRSTUVWXYZ0123456789#@$%&*+=<>_~░▒▓█"

                            Timer {
                                id: scrambleTimer
                                interval: 40
                                running: scrambleOverlay.visible
                                repeat: true
                                onTriggered: {
                                    scrambleOverlay.progress += 0.55
                                    var target = scrambleOverlay.currentTarget
                                    var len = target.length
                                    var chars = scrambleOverlay.glyphs
                                    var cutoff = Math.floor(scrambleOverlay.progress)

                                    var res = ""
                                    for (var i = 0; i < len; i++) {
                                        var ch = target.charAt(i)
                                        if (ch === " " || ch === "." || ch === "&" || ch === ",") {
                                            res += ch
                                        } else if (i < cutoff) {
                                            res += ch
                                        } else {
                                            var randIdx = Math.floor(Math.random() * chars.length)
                                            res += chars.charAt(randIdx)
                                        }
                                    }
                                    scrambleOverlay.displayText = res

                                    if (cutoff >= len + 16) {
                                        scrambleOverlay.progress = 0
                                        scrambleOverlay.phraseIndex = (scrambleOverlay.phraseIndex + 1) % scrambleOverlay.phrases.length
                                    }
                                }
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 8

                                    Text {
                                        text: "⚡"
                                        color: Theme.accentCyan
                                        font.pixelSize: 15
                                        font.bold: true
                                    }

                                    Text {
                                        text: scrambleOverlay.displayText
                                        color: Theme.accentCyan
                                        font.pixelSize: 13
                                        font.family: "Consolas, 'Courier New', monospace"
                                        font.bold: true
                                        font.letterSpacing: 1.1
                                    }

                                    // Blinking cyber block cursor
                                    Rectangle {
                                        width: 8
                                        height: 15
                                        color: Theme.accentCyan
                                        radius: 1
                                        SequentialAnimation on opacity {
                                            loops: Animation.Infinite
                                            NumberAnimation { from: 1.0; to: 0.15; duration: 280 }
                                            NumberAnimation { from: 0.15; to: 1.0; duration: 280 }
                                        }
                                    }
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "AI Neural Engine đang giải mã token đầu tiên..."
                                    color: Theme.textMuted
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }
                }
            }
        }

        // LIVE TRANSLATING HUD
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceMedium
            visible: translationController.status === "TRANSLATING"

            property int wordCount: {
                var s = translationInput.text.trim();
                return s.length > 0 ? s.split(/\s+/).length : 0;
            }
            property int charCount: translationInput.text.length
            property int lineCount: {
                var t = translationInput.text.trim();
                return t ? t.split('\n').length : 0;
            }

            Rectangle {
                implicitWidth: liveStreamRow.implicitWidth + 24
                implicitHeight: 24
                radius: 12
                color: Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.15)
                border.color: Theme.accentCyan
                border.width: 1
                RowLayout {
                    id: liveStreamRow
                    anchors.centerIn: parent
                    spacing: 5
                    Text {
                        id: liveSpinner
                        text: "⠋"
                        color: Theme.accentCyan
                        font.pixelSize: 13
                        font.bold: true
                        property var frames: ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
                        property int frameIdx: 0
                        Timer {
                            interval: 80
                            running: translationController.status === "TRANSLATING"
                            repeat: true
                            onTriggered: {
                                liveSpinner.frameIdx = (liveSpinner.frameIdx + 1) % liveSpinner.frames.length
                                liveSpinner.text = liveSpinner.frames[liveSpinner.frameIdx]
                            }
                        }
                    }
                    Text {
                        text: translationInput.text.trim().length === 0 ? "Khởi tạo neural..." : "Đang sinh từ..."
                        color: Theme.accentCyan
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
            }

            Rectangle {
                implicitWidth: liveWordsRow.implicitWidth + 24
                implicitHeight: 24
                radius: 12
                color: Qt.rgba(Theme.accentPurple.r, Theme.accentPurple.g, Theme.accentPurple.b, 0.15)
                border.color: Theme.accentPurple
                border.width: 1
                RowLayout {
                    id: liveWordsRow
                    anchors.centerIn: parent
                    spacing: 4
                    Text { text: "📝"; font.pixelSize: 10 }
                    Text { text: parent.parent.parent.wordCount + " Từ"; color: Theme.accentPurple; font.pixelSize: 11; font.bold: true }
                }
            }

            Rectangle {
                implicitWidth: liveCharsRow.implicitWidth + 24
                implicitHeight: 24
                radius: 12
                color: Qt.rgba(Theme.textSecondary.r, Theme.textSecondary.g, Theme.textSecondary.b, 0.15)
                border.color: Theme.textMuted
                border.width: 1
                RowLayout {
                    id: liveCharsRow
                    anchors.centerIn: parent
                    spacing: 4
                    Text { text: "🔤"; font.pixelSize: 10 }
                    Text { text: parent.parent.parent.charCount + " Ký tự"; color: Theme.textPrimary; font.pixelSize: 11; font.bold: true }
                }
            }

            Rectangle {
                implicitWidth: liveLinesCountRow.implicitWidth + 24
                implicitHeight: 24
                radius: 12
                color: parent.lineCount > 2 ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.15) : Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.15)
                border.color: parent.lineCount > 2 ? Theme.danger : Theme.success
                border.width: 1
                RowLayout {
                    id: liveLinesCountRow
                    anchors.centerIn: parent
                    spacing: 4
                    Text { text: parent.parent.parent.lineCount > 2 ? "🛑" : "🟢"; font.pixelSize: 10 }
                    Text { text: parent.parent.parent.lineCount + " Dòng"; color: parent.parent.parent.lineCount > 2 ? Theme.danger : Theme.success; font.pixelSize: 11; font.bold: true }
                }
            }

            Item { Layout.fillWidth: true }
        }
        
        // QA HUD
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceMedium
            visible: translationController.status !== "TRANSLATING" && translationController.status !== "PENDING"
            
            property real durationSec: {
                if (!translationController.currentStartTime || !translationController.currentEndTime) return 1.0;
                function toSec(t) {
                    var p = t.replace(',', ':').split(':');
                    if (p.length < 4) return 0;
                    return parseInt(p[0])*3600 + parseInt(p[1])*60 + parseInt(p[2]) + parseInt(p[3])/1000;
                }
                var d = toSec(translationController.currentEndTime) - toSec(translationController.currentStartTime);
                return d > 0.001 ? d : 1.0;
            }
            property string cleanText: {
                return translationInput.text.replace(/<[^>]*>/g, "");
            }
            property real cps: {
                return cleanText.length / durationSec;
            }
            property int cpl: {
                var lines = cleanText.split('\n');
                var max = 0;
                for (var i=0; i<lines.length; i++) {
                    if (lines[i].length > max) max = lines[i].length;
                }
                return max;
            }
            property int lineCount: {
                return cleanText ? cleanText.split('\n').length : 0;
            }
            
            property color cpsColor: cps <= 17 ? Theme.success : (cps <= 20 ? Theme.warning : Theme.danger)
            property color cplColor: cpl <= 40 ? Theme.success : (cpl <= 42 ? Theme.warning : Theme.danger)
            property color lineCountColor: lineCount <= 2 ? Theme.success : Theme.danger
            
            Rectangle {
                implicitWidth: cpsRow.implicitWidth + 24
                implicitHeight: 24
                radius: 12
                color: Qt.rgba(parent.cpsColor.r, parent.cpsColor.g, parent.cpsColor.b, 0.15)
                border.color: parent.cpsColor
                border.width: 1
                RowLayout {
                    id: cpsRow
                    anchors.centerIn: parent
                    spacing: 4
                    Text { text: parent.parent.parent.cpsColor === Theme.danger ? "🛑" : parent.parent.parent.cpsColor === Theme.warning ? "🟡" : "🟢"; font.pixelSize: 10 }
                    Text { text: "CPS: " + parent.parent.parent.cps.toFixed(1); color: parent.parent.parent.cpsColor; font.pixelSize: 11; font.bold: true }
                }
            }
            
            Rectangle {
                implicitWidth: cplRow.implicitWidth + 24
                implicitHeight: 24
                radius: 12
                color: Qt.rgba(parent.cplColor.r, parent.cplColor.g, parent.cplColor.b, 0.15)
                border.color: parent.cplColor
                border.width: 1
                RowLayout {
                    id: cplRow
                    anchors.centerIn: parent
                    spacing: 4
                    Text { text: parent.parent.parent.cplColor === Theme.danger ? "🛑" : parent.parent.parent.cplColor === Theme.warning ? "🟡" : "🟢"; font.pixelSize: 10 }
                    Text { text: "CPL: " + parent.parent.parent.cpl + "/42"; color: parent.parent.parent.cplColor; font.pixelSize: 11; font.bold: true }
                }
            }
            
            Rectangle {
                implicitWidth: linesRow.implicitWidth + 24
                implicitHeight: 24
                radius: 12
                color: Qt.rgba(parent.lineCountColor.r, parent.lineCountColor.g, parent.lineCountColor.b, 0.15)
                border.color: parent.lineCountColor
                border.width: 1
                RowLayout {
                    id: linesRow
                    anchors.centerIn: parent
                    spacing: 4
                    Text { text: parent.parent.parent.lineCountColor === Theme.danger ? "🛑" : "🟢"; font.pixelSize: 10 }
                    Text { text: parent.parent.parent.lineCount + " Dòng"; color: parent.parent.parent.lineCountColor; font.pixelSize: 11; font.bold: true }
                }
            }
            Item { Layout.fillWidth: true }
        }
        
        Text {
            visible: translationController.status === "ERROR"
            text: "Dịch thất bại. Lỗi xử lý mô hình AI."
            color: Theme.danger
            font.pixelSize: 12
            Layout.fillWidth: true
        }
        
        Item { Layout.fillHeight: true }
        
        // 3. THANH FOOTER ĐÁY CỘT GIỮA (Chứa phím tắt bên trái & 2 nút bấm bên phải)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            color: Qt.rgba(1, 1, 1, 0.08)
            radius: 12


            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12

                // Gợi ý phím tắt bên trái (Matching Design Mockup)
                RowLayout {
                    id: shortcutHintRow
                    Layout.alignment: Qt.AlignVCenter
                    visible: workspace.width >= 580
                    spacing: 6
                    Text {
                        text: "Nhấn"
                        color: Qt.rgba(1, 1, 1, 0.85)
                        font.pixelSize: 12
                        font.bold: true
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Rectangle {
                        implicitWidth: keyHintText.implicitWidth + 12
                        implicitHeight: 22
                        radius: 6
                        color: Qt.rgba(1, 1, 1, 0.9)
                        Layout.alignment: Qt.AlignVCenter
                        Text {
                            id: keyHintText
                            anchors.centerIn: parent
                            text: "Ctrl + Enter"
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.accentSapphire
                        }
                    }
                    Text {
                        text: "để duyệt nhanh câu kế"
                        color: Qt.rgba(1, 1, 1, 0.85)
                        font.pixelSize: 12
                        font.bold: true
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }

                AppButton {
                    objectName: "btnRetry"
                    text: "⚡ Dịch lại"
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 105
                    Layout.minimumWidth: 70
                    isDarkGlass: true
                    visible: ["ERROR", "TRANSLATED", "EDITED", "ACCEPTED"].indexOf(translationController.status) >= 0
                    enabled: !workspace.executionLocked && translationController.engineStatus !== "Translating" &&
                             ["ERROR", "TRANSLATED", "EDITED", "ACCEPTED"].indexOf(translationController.status) >= 0
                    onClicked: translateRequested(langSelector.sourceLang)
                }

                AppButton {
                    objectName: "btnTranslate"
                    visible: translationController.status === "PENDING" || translationController.status === "TRANSLATING"
                    text: translationController.status === "TRANSLATING" ? "◌ Đang dịch..." : "⚡ Dịch (Ctrl+T)"
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 120
                    Layout.minimumWidth: 80
                    isPrimary: true
                    enabled: !workspace.executionLocked && translationController.engineStatus !== "Translating" &&
                             translationController.status !== "TRANSLATING"
                    onClicked: translateRequested(langSelector.sourceLang)
                }

                AppButton {
                    objectName: "btnAccept"
                    text: "✓ Chấp nhận (Accept) ➔"
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: Math.max(185, implicitWidth)
                    Layout.minimumWidth: 100
                    isPrimary: true
                    visible: true
                    enabled: !workspace.executionLocked && (translationController.status === "TRANSLATED" || translationController.status === "EDITED" || translationController.status === "ACCEPTED")
                    onClicked: acceptRequested(translationInput.text)
                }
            }
        }
    }
}
