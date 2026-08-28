import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QtQuick.Dialogs
import "theme"
import "components"

ApplicationWindow {
    visible: true
    width: 1280
    height: 720
    minimumWidth: 1024
    minimumHeight: 600
    title: "AI Subtitle Translator - Professional Workspace"
    color: Theme.bgApp

    flags: Qt.FramelessWindowHint | Qt.Window

    // ==========================================
    // CÁC BIẾN TOÀN CỤC (SỬA LỖI REFERENCE ERROR)
    // ==========================================
    property string globalStorySummary: ""
    property string currentProjectName: "Untitled"
    property bool hasUnsavedChanges: false

    // BỔ SUNG BIẾN TRACK TIẾN TRÌNH
    property int totalSubtitleCount: subListView.count
    property int acceptedSubtitleCount: 0

    // ==========================================
    // P2.5-T2: PROFESSIONAL HEADER
    // ==========================================
    header: AppHeader {
        projectName: currentProjectName
        isSaved: !hasUnsavedChanges
        
        onOpenSrtClicked: importSrtDialog.open()
        onOpenProjectClicked: loadProjectDialog.open()
        onSaveClicked: saveProjectDialog.open()
        onExportClicked: {
            if (projectController.validateBeforeExport()) {
                exportSrtDialog.open()
            }
        }
    }

    // ==========================================
    // P2.5-T7: PROFESSIONAL STATUS BAR (THÊM MỚI)
    // ==========================================
    footer: AppStatusBar {
        totalItems: totalSubtitleCount
        acceptedItems: acceptedSubtitleCount
        aiState: translationController.status === "TRANSLATING" ? "Translating..." : "Ready"
        // VRAM tạm thời gán cứng 3.6 để bạn thấy màu Vàng/Đỏ cảnh báo. Sẽ nối API sau.
        vramUsage: translationController.status === "TRANSLATING" ? 3.8 : 1.2 
    }

    // ==========================================
    // MAIN WINDOW SHELL (3-COLUMN RESPONSIVE LAYOUT)
    // ==========================================
    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal
        
        handle: Rectangle {
            implicitWidth: 2
            color: SplitHandle.pressed ? Theme.accentSecondary : (SplitHandle.hovered ? Theme.border : "transparent")
            Behavior on color { ColorAnimation { duration: Theme.animDuration } }
        }

        // CỘT 1: SUBTITLE NAVIGATOR
        Rectangle {
            SplitView.preferredWidth: 320
            SplitView.minimumWidth: 250
            color: Theme.bgSurface
            
            SubtitleListView {
                id: subListView
                anchors.fill: parent
                model: subtitleModel 
            }
        }

        // CỘT 2: TRANSLATION WORKSPACE
        Rectangle {
            SplitView.fillWidth: true
            SplitView.minimumWidth: 400
            color: Theme.bgApp
            
            TranslationWorkspace {
                id: transWorkspace
                anchors.fill: parent
                anchors.margins: Theme.spaceMedium
                hasSelection: subListView.currentIndex >= 0

                onTranslateRequested: (sourceLang) => {
                    translationController.requestTranslation(subListView.currentIndex, sourceLang, "Vietnamese", globalStorySummary)
                }
                
                onAcceptRequested: (text) => {
                    let isSuccess = translationController.acceptTranslation(subListView.currentIndex, text)
                    if (isSuccess && subListView.currentIndex < subListView.count - 1) {
                        subListView.currentIndex += 1
                        acceptedSubtitleCount += 1
                    }
                }
            }
        }

        // CỘT 3: CONTEXT INSPECTOR
        Rectangle {
            SplitView.preferredWidth: 300
            SplitView.minimumWidth: 250
            color: Theme.bgSurface
            
            ContextInspector {
                anchors.fill: parent
                anchors.margins: Theme.spaceMedium
            }
        }
    }

    // ==========================================
    // DIALOGS & CONNECTIONS
    // ==========================================
    Toast { id: appToast }
    
    FileDialog { 
        id: importSrtDialog; 
        title: "Chọn file SRT gốc"; 
        nameFilters: ["Subtitle files (*.srt)"]; 
        onAccepted: projectController.importSrt(selectedFile) 
    }
    
    FileDialog { 
        id: loadProjectDialog; 
        title: "Mở file dự án"; 
        nameFilters: ["AI Subtitle Project (*.aisrt)"]; 
        onAccepted: projectController.loadProject(selectedFile) 
    }
    
    FileDialog { 
        id: saveProjectDialog; 
        title: "Lưu dự án"; 
        fileMode: FileDialog.SaveFile; 
        nameFilters: ["AI Subtitle Project (*.aisrt)"]; 
        defaultSuffix: "aisrt"; 
        onAccepted: {
            projectController.saveProject(selectedFile, globalStorySummary, transWorkspace.getSourceLanguage(), "Vietnamese")
            hasUnsavedChanges = false // Reset trạng thái Save
        }
    }
    
    FileDialog { 
        id: exportSrtDialog; 
        title: "Xuất file SRT đã dịch"; 
        fileMode: FileDialog.SaveFile; 
        nameFilters: ["Subtitle files (*.srt)"]; 
        defaultSuffix: "srt"; 
        onAccepted: projectController.exportSrt(selectedFile) 
    }

    Connections {
        target: translationController
        function onNotify(title, msg) { appToast.show(title, msg) }
    }

    Connections {
        target: projectController
        function onNotify(title, msg) { appToast.show(title, msg) }
        function onLanguageLoaded(lang) { transWorkspace.setSourceLanguage(lang) }
        function onProjectLoaded(summary) { 
            globalStorySummary = summary
            hasUnsavedChanges = false // Reset khi load project mới
        }
    }
    // ==========================================
    // P2.5-T16: GLOBAL KEYBOARD SHORTCUTS
    // ==========================================
    
    // 1. Nhóm thao tác File
    Shortcut { 
        sequence: "Ctrl+O"
        onActivated: importSrtDialog.open() 
    }
    Shortcut { 
        sequence: "Ctrl+Shift+O"
        onActivated: loadProjectDialog.open() 
    }
    Shortcut { 
        sequence: "Ctrl+S"
        onActivated: saveProjectDialog.open() 
    }
    Shortcut { 
        sequence: "Ctrl+Shift+S"
        onActivated: {
            if (projectController.validateBeforeExport()) {
                exportSrtDialog.open()
            }
        }
    }

    // 2. Nhóm điều hướng (Dùng Alt + Lên/Xuống để nhảy câu thoại nhanh)
    Shortcut {
        sequence: "Alt+Up"
        onActivated: {
            if (subListView.count > 0 && subListView.currentIndex > 0) {
                subListView.currentIndex -= 1
            }
        }
    }
    Shortcut {
        sequence: "Alt+Down"
        onActivated: {
            if (subListView.count > 0 && subListView.currentIndex < subListView.count - 1) {
                subListView.currentIndex += 1
            }
        }
    }

    // 3. Nhóm thao tác AI (Kích hoạt dịch)
    Shortcut {
        sequence: "Ctrl+T"
        onActivated: {
            if (transWorkspace.hasSelection && translationController.status !== "TRANSLATING") {
                transWorkspace.translateRequested(transWorkspace.getSourceLanguage())
            }
        }
    }
}