import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QtQuick.Dialogs

ApplicationWindow {
    visible: true
    width: 1024
    height: 720
    x: Screen.width / 2 - width / 2
    y: Screen.height / 2 - height / 2
    title: "AI Subtitle Translator - Phase 1 MVP"
    color: "#18181B"

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Sidebar: Context & Danh sách Subtitle
        Rectangle {
            Layout.preferredWidth: 350
            Layout.fillHeight: true
            color: "#27272A"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Text { text: "📖 Context & Story Summary"; color: "#A1A1AA"; font.bold: true }

                Rectangle {
                    Layout.fillWidth: true
                    height: 120
                    color: "#18181B"
                    border.color: "#3F3F46"
                    radius: 6
                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 10
                        TextArea {
                            id: storySummaryInput
                            placeholderText: "Nhập tóm tắt cốt truyện, giới tính nhân vật, quy tắc dịch..."
                            color: "#F4F4F5"
                            wrapMode: Text.WordWrap
                            background: null
                        }
                    }
                }

                Text { text: "💬 Danh sách Subtitle"; color: "#A1A1AA"; font.bold: true; Layout.topMargin: 5 }

                ListView {
                    id: subListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: subtitleModel
                    clip: true
                    spacing: 8
                    
                    onCurrentIndexChanged: {
                        if (currentIndex >= 0) translationController.loadSubtitle(currentIndex)
                    }
                    Component.onCompleted: {
                        if (count > 0) translationController.loadSubtitle(0)
                    }

                    delegate: Rectangle {
                        width: subListView.width
                        height: 80
                        color: status === "ACCEPTED" ? "#166534" : "#3F3F46"
                        radius: 6
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 10; spacing: 4
                            Text { text: "#" + subIndex + " | " + startTime + " → " + endTime; color: "#A1A1AA"; font.pixelSize: 12 }
                            Text { 
                                // Nếu chưa duyệt hiển thị original, đã duyệt hiển thị translation
                                text: status === "ACCEPTED" ? translationText : originalText
                                color: "#F4F4F5"
                                font.pixelSize: 14
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true 
                            }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: subListView.currentIndex = index }
                    }
                    highlight: Rectangle { color: "#3B82F6"; radius: 6; opacity: 0.3 }
                    highlightFollowsCurrentItem: true
                }
            }
        }

        // Main Panel
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#18181B"

            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width * 0.7
                spacing: 20

                // --- THANH CHỌN NGÔN NGỮ (PHASE 1.6) ---
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 15

                    Text { text: "Ngôn ngữ nguồn:"; color: "#A1A1AA"; font.pixelSize: 14 }
                    
                    ComboBox {
                        id: sourceLangCombo
                        model: ["English", "Japanese", "Chinese (Simplified)", "Chinese (Traditional)", "Korean", "Spanish", "French", "German", "Russian"]
                        font.pixelSize: 14
                        currentIndex: 0 // Mặc định là English
                        // Styling cho combobox (tùy chọn)
                    }

                    Text { text: " ➔ "; color: "#A1A1AA"; font.pixelSize: 16; font.bold: true }

                    Text { text: "Đích:"; color: "#A1A1AA"; font.pixelSize: 14 }
                    
                    ComboBox {
                        id: targetLangCombo
                        model: ["Vietnamese"] // Cố định
                        font.pixelSize: 14
                        enabled: false // Không cho phép chọn ngôn ngữ khác
                    }
                }

                Text {
                    text: "Trạng thái: " + translationController.status
                    color: translationController.status === "TRANSLATED" ? "#4CAF50" : (translationController.status === "TRANSLATING" ? "#3B82F6" : "#A1A1AA")
                    font.pixelSize: 14
                    font.bold: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 200
                    color: "#27272A"
                    radius: 8
                    border.color: translationController.status === "TRANSLATING" ? "#3B82F6" : "transparent"
                    border.width: 2
                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 15
                        TextArea {
                            id: translationInput
                            text: translationController.currentTranslation
                            color: translationController.status === "PENDING" ? "#F4F4F5" : "#A7F3D0"
                            font.pixelSize: 18
                            wrapMode: Text.WordWrap
                            background: null
                            selectByMouse: true
                            
                            // THÊM ĐIỀU KIỆN CHUẨN ĐỂ ĐÁNH DẤU EDITED Ở ĐÚNG VỊ TRÍ
                            // THÊM ĐIỀU KIỆN CHUẨN ĐỂ ĐÁNH DẤU EDITED Ở ĐÚNG VỊ TRÍ
                            onTextChanged: {
                                // Chỉ chuyển sang EDITED nếu:
                                // 1. Ô text đang được trỏ chuột (focus)
                                // 2. AI không phải đang dịch
                                // 3. Text thực sự khác với text do Backend trả về (Tức là user vừa tự gõ thêm)
                                if (translationInput.focus && 
                                    translationController.status !== "TRANSLATING" &&
                                    translationInput.text !== translationController.currentTranslation) {
                                    translationController.markAsEdited()
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 20

                    Button {
                        text: "↻ Retry"
                        font.pixelSize: 16
                        enabled: translationController.status !== "TRANSLATING" && subListView.currentIndex >= 0
                        onClicked: translationController.requestTranslation(subListView.currentIndex, sourceLangCombo.currentText, "Vietnamese", storySummaryInput.text)
                    }
                    Button {
                        text: "✦ Dịch AI"
                        font.pixelSize: 16
                        enabled: translationController.status !== "TRANSLATING" && subListView.currentIndex >= 0
                        onClicked: translationController.requestTranslation(subListView.currentIndex, sourceLangCombo.currentText, "Vietnamese", storySummaryInput.text)
                    }
                    Button {
                        text: "✓ Accept"
                        font.pixelSize: 16
                        enabled: (translationController.status === "TRANSLATED" || translationController.status === "EDITED" || translationController.status === "ACCEPTED") && subListView.currentIndex >= 0
                        onClicked: {
                            // CHỈ NHẢY CÂU KHI BACKEND TRẢ VỀ TRUE
                            let isSuccess = translationController.acceptTranslation(subListView.currentIndex, translationInput.text)
                            if (isSuccess && subListView.currentIndex < subListView.count - 1) {
                                subListView.currentIndex += 1
                            }
                        }
                    }
                }

                Text {
                    id: notificationText
                    Layout.fillWidth: true
                    Layout.topMargin: 15
                    text: "Dự án đã sẵn sàng."
                    color: "#A1A1AA"
                    font.pixelSize: 15
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 60
                color: "#27272A"
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 15
                    
                    Button {
                        text: "📁 Mở SRT"
                        font.pixelSize: 14
                        onClicked: importSrtDialog.open()
                    }
                    Button {
                        text: "📂 Mở Project"
                        font.pixelSize: 14
                        onClicked: loadProjectDialog.open()
                    }
                    Button {
                        text: "💾 Lưu Project"
                        font.pixelSize: 14
                        onClicked: saveProjectDialog.open() // FIX: Khôi phục lại đúng luồng Dialog
                    }   
                    Button {
                        text: "📤 Xuất SRT"
                        font.pixelSize: 14
                        font.bold: true
                        onClicked: {
                            if (projectController.validateBeforeExport()) {
                                exportSrtDialog.open()
                            }
                        }
                    }
                }
            }

            FileDialog { id: importSrtDialog; title: "Chọn file SRT gốc"; nameFilters: ["Subtitle files (*.srt)"]; onAccepted: projectController.importSrt(selectedFile) }
            FileDialog { id: loadProjectDialog; title: "Mở file dự án"; nameFilters: ["AI Subtitle Project (*.aisrt)"]; onAccepted: projectController.loadProject(selectedFile) }
            FileDialog { 
                id: saveProjectDialog; 
                title: "Lưu dự án"; 
                fileMode: FileDialog.SaveFile; 
                nameFilters: ["AI Subtitle Project (*.aisrt)"]; 
                defaultSuffix: "aisrt"; 
                // TRUYỀN ĐỘNG BIẾN NGÔN NGỮ TỪ COMBOBOX VÀO CONTROLLER
                onAccepted: projectController.saveProject(selectedFile, storySummaryInput.text, sourceLangCombo.currentText, "Vietnamese") 
            }
            FileDialog { id: exportSrtDialog; title: "Xuất file SRT đã dịch"; fileMode: FileDialog.SaveFile; nameFilters: ["Subtitle files (*.srt)"]; defaultSuffix: "srt"; onAccepted: projectController.exportSrt(selectedFile) }
            
            Connections {
                target: translationController
                function onNotify(title, msg) {
                    notificationText.text = msg
                    notificationText.color = (title === "SUCCESS") ? "#4CAF50" : "#F87171"
                }
                function onTranslationUpdated(newText) {
                    // Cập nhật text an toàn để không bị lỗi vỡ Binding khi user gõ phím
                    if (translationInput.text !== newText) {
                        translationInput.text = newText
                    }
                }
            }
            Connections {
                target: projectController
                
                // 1. Bắt tín hiệu khôi phục ngôn ngữ nguồn cho Dropdown
                function onLanguageLoaded(lang) {
                    let index = sourceLangCombo.find(lang)
                    if (index !== -1) {
                        sourceLangCombo.currentIndex = index
                    }
                }
                // 2. Bắt tín hiệu khôi phục Story Summary vào ô text
                function onProjectLoaded(summary) {
                    storySummaryInput.text = summary
                    
                    // THỦ THUẬT: Ép currentIndex đổi về -1 rồi nhảy lại 0 để kích hoạt loadSubtitle
                    subListView.currentIndex = -1
                    if (subListView.count > 0) {
                        subListView.currentIndex = 0
                    } else {
                        translationController.loadSubtitle(-1)
                    }
                }
                // 3. Bắt tín hiệu thông báo (Lưu/Mở thành công hoặc thất bại)
                function onNotify(title, msg) {
                    notificationText.text = msg
                    notificationText.color = (title === "SUCCESS") ? "#4CAF50" : "#F87171"
                }
            }
        }
    }
}