import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
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
    
    Rectangle { anchors.fill: parent; color: Theme.bgApp }
    
    EmptyWorkspace {
        anchors.fill: parent
        visible: !workspace.hasSelection
        emptyStateMode: typeof projectController !== "undefined" && projectController.hasProject ? "no_selection" : "no_project"
        onOpenSrtClicked: workspace.openSrtRequested()
        onOpenProjectClicked: workspace.openProjectRequested()
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spaceLarge
        spacing: Theme.spaceMedium
        visible: workspace.hasSelection
        
        // Status & Original header
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceSmall
            
            Text {
                text: "Trạng thái:"
                color: Theme.textMuted
                font.pixelSize: 12
            }
            Rectangle {
                implicitWidth: statusBadge.implicitWidth + 16
                implicitHeight: 20
                radius: 10
                color: translationController.status === "ACCEPTED" ? Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.15) :
                       translationController.status === "ERROR" ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.15) :
                       translationController.status === "TRANSLATED" || translationController.status === "EDITED" ? Qt.rgba(Theme.accentPurple.r, Theme.accentPurple.g, Theme.accentPurple.b, 0.15) :
                       translationController.status === "TRANSLATING" ? Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.15) :
                       Theme.bgSurfaceSoft
                
                Text {
                    id: statusBadge
                    anchors.centerIn: parent
                    text: translationController.status === "ACCEPTED" ? "[ ĐÃ DUYỆT ]" : 
                          translationController.status === "TRANSLATED" ? "ĐÃ DỊCH ✦" :
                          translationController.status === "EDITED" ? "ĐÃ SỬA ●" :
                          translationController.status === "TRANSLATING" ? "Đang dịch…" : 
                          translationController.status === "ERROR" ? "LỖI ✕" : "CHỜ DỊCH"
                    color: translationController.status === "ACCEPTED" ? Theme.success : 
                           translationController.status === "TRANSLATED" || translationController.status === "EDITED" ? Theme.accentPurple : 
                           translationController.status === "ERROR" ? Theme.danger : 
                           translationController.status === "TRANSLATING" ? Theme.accentCyan : Theme.textMuted
                    font.pixelSize: 10
                    font.bold: true
                }
            }
            Item { Layout.fillWidth: true }
            LanguageSelector {
                id: langSelector
                objectName: "sourceLangCombo"
            }
        }
        
        Text {
            text: "CÂU GỐC"
            color: Theme.textMuted
            font.pixelSize: 11
            font.bold: true
        }
        
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            color: Theme.bgSurface
            radius: Theme.radius
            border.color: Theme.border
            border.width: 1
            
            ScrollView {
                anchors.fill: parent
                anchors.margins: Theme.spaceMedium
                TextArea {
                    text: translationController.currentOriginal
                    color: Theme.textPrimary
                    font.pixelSize: 15
                    wrapMode: Text.WordWrap
                    readOnly: true
                    background: null
                    selectByMouse: true
                }
            }
        }
        
        Item { Layout.preferredHeight: Theme.spaceMedium }
        
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceSmall
            
            Text {
                text: "BẢN DỊCH TIẾNG VIỆT"
                color: Theme.textMuted
                font.pixelSize: 11
                font.bold: true
            }

            // Live Translating badge with pulsing animation
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

            Item { Layout.fillWidth: true }

            // Live Word & Char count in header
            RowLayout {
                spacing: 6
                visible: translationController.status === "TRANSLATING" || translationInput.text.length > 0

                property int wordCount: {
                    var s = translationInput.text.trim();
                    return s.length > 0 ? s.split(/\s+/).length : 0;
                }

                Text {
                    text: parent.wordCount + " từ"
                    color: translationController.status === "TRANSLATING" ? Theme.accentCyan : Theme.textSecondary
                    font.pixelSize: 11
                    font.bold: translationController.status === "TRANSLATING"
                }

                Text {
                    text: "•"
                    color: Theme.textDisabled
                    font.pixelSize: 10
                }

                Text {
                    text: translationInput.text.length + " ký tự"
                    color: Theme.textMuted
                    font.pixelSize: 11
                }
            }
        }
        
        Rectangle {
            id: translationBox
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            color: Theme.bgSurfaceElevated
            radius: Theme.radius
            border.color: translationController.status === "TRANSLATING" ? Theme.accentCyan : 
                          (translationInput.activeFocus ? Theme.accentCyan : Theme.border)
            border.width: translationController.status === "TRANSLATING" ? 2 : 1
            clip: true
            
            ScrollView {
                anchors.fill: parent
                anchors.margins: Theme.spaceMedium
                TextArea {
                    objectName: "translationInput"
                    id: translationInput
                    text: translationController.currentTranslation
                    placeholderText: translationController.status === "TRANSLATING" ? "" : "Nhập bản dịch tiếng Việt tại đây..."
                    placeholderTextColor: Theme.textDisabled
                    color: Theme.textPrimary
                    font.pixelSize: 15
                    wrapMode: Text.WordWrap
                    background: null
                    selectByMouse: true
                    readOnly: translationController.status === "TRANSLATING" || workspace.executionLocked
                    onTextChanged: {
                        if (focus && translationController.currentTranslation !== text) {
                            translationController.updateCurrentTranslation(text)
                        }
                    }
                }
            }

            // Scramble Decoder Overlay (Hiệu ứng giải mã chữ ngẫu nhiên matrix/cyber khi đang chờ sinh token)
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

            // Top scanner bar when translating
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 2
                color: "transparent"
                visible: translationController.status === "TRANSLATING"

                Rectangle {
                    id: streamScanner
                    height: 2
                    width: Math.max(translationBox.width * 0.35, 60)
                    color: Theme.accentCyan
                    radius: 1

                    NumberAnimation on x {
                        from: -streamScanner.width
                        to: translationBox.width
                        duration: 1200
                        loops: Animation.Infinite
                        running: translationController.status === "TRANSLATING"
                    }
                }
            }
        }

        // LIVE TRANSLATING HUD (Hiển thị thời gian thực khi đang sinh bản dịch)
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

            // Badge 1: Trạng thái sinh với spinner động
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

            // Badge 2: Số từ
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

            // Badge 3: Số ký tự
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

            // Badge 4: Số dòng
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
        
        // QA HUD (Hiển thị sau khi dịch xong hoặc đã có bản dịch)
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
        
        RowLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.topMargin: Theme.spaceSmall
            Layout.bottomMargin: Theme.spaceSmall
            spacing: Theme.spaceMedium
            
            Item {
                Layout.fillWidth: true
                visible: !workspace.compactActions
            }
            
            AppButton {
                objectName: "btnRetry"
                text: "↻ Thử lại"
                Layout.minimumWidth: 80
                Layout.preferredWidth: workspace.compactActions ? 80 : 100
                Layout.maximumWidth: 120
                enabled: !workspace.executionLocked && translationController.engineStatus !== "Translating" &&
                         ["ERROR", "TRANSLATED", "EDITED", "ACCEPTED"].indexOf(translationController.status) >= 0
                onClicked: translateRequested(langSelector.sourceLang)
            }
            
            AppButton {
                objectName: "btnTranslate"
                text: translationController.status === "TRANSLATING" ? "◌ Đang dịch..." : "⚡ Dịch (Ctrl+T)"
                Layout.minimumWidth: 120
                Layout.preferredWidth: workspace.compactActions ? 120 : 140
                Layout.maximumWidth: 160
                isPrimary: true
                enabled: !workspace.executionLocked && translationController.engineStatus !== "Translating" &&
                         translationController.status !== "TRANSLATING"
                onClicked: translateRequested(langSelector.sourceLang)
            }
            
            AppButton {
                objectName: "btnAccept"
                text: "✓ Duyệt (Ctrl+Enter)"
                Layout.minimumWidth: 130
                Layout.preferredWidth: workspace.compactActions ? 130 : 160
                Layout.maximumWidth: 180
                enabled: !workspace.executionLocked && (translationController.status === "TRANSLATED" || translationController.status === "EDITED")
                onClicked: acceptRequested(translationInput.text)
            }
        }
    }
}
