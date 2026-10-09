import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QtQuick.Dialogs
import "theme"
import "components"

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 1280
    height: 720
    minimumWidth: 1024
    minimumHeight: 600
    flags: Qt.FramelessWindowHint | Qt.Window
    title: "AI Subtitle Translator - Professional Workspace"
    color: Theme.bgApp

    // THÊM MỚI: Biến toàn cục hứng Story Summary (đặt ở cấp cao nhất)
    property string globalStorySummary: ""
    // P2.5-T13-D0: manual responsive acceptance only.
    property bool responsiveTestToolsEnabled: Qt.application.arguments.indexOf("--dev-tools") >= 0

    // ==========================================
    // P2.5-T2: PROJECT HEADER
    // ==========================================
    header: AppHeader {
        projectName: "Workspace"
        hasProject: projectController.hasProject
        isSaved: projectController.hasProject && !projectController.isDirty
        hasProjectData: subListView.count > 0
        projectMutationLocked: batchController.executionLocked
        onOpenSrtClicked: {
            if (!batchController.executionLocked) importSrtDialog.open()
        }
        onOpenProjectClicked: {
            if (!batchController.executionLocked) loadProjectDialog.open()
        }
        onSaveClicked: saveProjectDialog.open()
        onExportClicked: {
            if (projectController.validateBeforeExport()) {
                exportSrtDialog.open()
            }
        }
        onModelManagerClicked: modelManagerDialog.open()
    }

    footer: AppStatusBar {
        id: appStatusBar
        totalCount: translationController.totalSubtitleCount
        acceptedCount: translationController.acceptedCount
        engineStatus: {
            return translationController.engineStatus
        }
        vramUsed: typeof translationController.vramUsed !== "undefined" ? translationController.vramUsed : -1.0
        vramTotal: typeof translationController.vramTotal !== "undefined" ? translationController.vramTotal : -1.0
    }

    // ==========================================
    // S2-T2: MAIN WINDOW SHELL (3-COLUMN LAYOUT)
    // ==========================================
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        BatchControlBar {
            id: batchControlBar
            Layout.fillWidth: true
            sourceLanguage: transWorkspace.getSourceLanguage()
            targetLanguage: "Vietnamese"
            storySummary: mainWindow.globalStorySummary
        }

        SplitView {
            Layout.fillWidth: true
            Layout.fillHeight: true
        orientation: Qt.Horizontal
        handle: Rectangle {
            implicitWidth: 1
            color: SplitHandle.pressed ? Theme.accentCyan : (SplitHandle.hovered ? Theme.textMuted : Theme.border)
            Behavior on color { ColorAnimation { duration: Theme.animDuration } }
        }

        // CỘT 1: SUBTITLE NAVIGATOR
        Rectangle {
            SplitView.preferredWidth: 320
            SplitView.minimumWidth: 250
            SplitView.maximumWidth: 450
            color: Theme.bgSurface

            SubtitleListView {
                id: subListView // ĐÃ FIX: Khai báo ID cho danh sách
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
                totalCount: subListView.count
                executionLocked: batchController.executionLocked

                onTranslateRequested: (sourceLang) => {
                    translationController.requestTranslation(subListView.currentIndex, sourceLang, "Vietnamese", globalStorySummary)
                }

                onAcceptRequested: (text) => {
                    let isSuccess = translationController.acceptTranslation(subListView.currentIndex, text)
                    if (isSuccess && subListView.currentIndex < subListView.count - 1) {
                        subListView.currentIndex += 1
                    }
                }
                onOpenSrtRequested: {
                    if (!batchController.executionLocked) importSrtDialog.open()
                }
                onOpenProjectRequested: {
                    if (!batchController.executionLocked) loadProjectDialog.open()
                }
            }
        }

        // CỘT 3: CONTEXT INSPECTOR (Giữ chỗ cho S2-T8)
        Rectangle {
            SplitView.preferredWidth: 300
            SplitView.minimumWidth: 250
            SplitView.maximumWidth: 400
            color: Theme.bgSurface

            ContextInspector {
                anchors.fill: parent
                anchors.margins: Theme.spaceMedium
            }
        }
    }
    }

    // ==========================================
    // DIALOGS & CONNECTIONS
    // ==========================================
    Toast {
        id: appToast
    }
    FileDialog { id: importSrtDialog; title: "Chọn file SRT gốc"; nameFilters: ["Subtitle files (*.srt)"]; onAccepted: projectController.importSrt(selectedFile) }
    FileDialog { id: loadProjectDialog; title: "Mở file dự án"; nameFilters: ["AI Subtitle Project (*.aisrt)"]; onAccepted: projectController.loadProject(selectedFile) }

    FileDialog {
        id: saveProjectDialog;
        title: "Lưu dự án";
        fileMode: FileDialog.SaveFile;
        nameFilters: ["AI Subtitle Project (*.aisrt)"];
        defaultSuffix: "aisrt";
        // ĐÃ FIX: Xóa onAccepted bị lặp
        onAccepted: projectController.saveProject(selectedFile, globalStorySummary, transWorkspace.getSourceLanguage(), "Vietnamese")
    }

    FileDialog { id: exportSrtDialog; title: "Xuất file SRT đã dịch"; fileMode: FileDialog.SaveFile; nameFilters: ["Subtitle files (*.srt)"]; defaultSuffix: "srt"; onAccepted: projectController.exportSrt(selectedFile) }

    Connections {
        target: translationController
        function onNotify(title, msg) { appToast.show(title, msg) }
    }

    Connections {
        target: projectController
        function onNotify(title, msg) { appToast.show(title, msg) }
        function onLanguageLoaded(lang) { transWorkspace.setSourceLanguage(lang) }
        function onProjectLoaded(summary) { globalStorySummary = summary }
        function onQaExportWarningRequired(filePath, errorCount) {
            qaConfirmDialog.targetFilePath = filePath
            qaConfirmDialog.errorCount = errorCount
            qaConfirmDialog.open()
        }
    }

    Dialog {
        id: qaConfirmDialog
        title: "Cảnh báo chất lượng phụ đề (QA)"
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Yes | Dialog.No

        property string targetFilePath: ""
        property int errorCount: 0

        ColumnLayout {
            spacing: Theme.spaceMedium
            Text {
                text: "⚠️ Có " + qaConfirmDialog.errorCount + " dòng phụ đề vi phạm quy tắc hiển thị (Lỗi đỏ)."
                color: Theme.danger
                font.pixelSize: 14
                font.bold: true
            }
            Text {
                text: "Bạn có chắc chắn muốn bỏ qua cảnh báo và tiếp tục xuất file SRT không?"
                color: Theme.textSecondary
                font.pixelSize: 13
            }
        }

        onAccepted: {
            if (targetFilePath !== "") {
                projectController.exportSrt(targetFilePath, true)
            }
        }
    }

    ModelManagerDialog {
        id: modelManagerDialog
    }

    Connections {
        target: typeof modelController !== "undefined" ? modelController : null
        function onNotify(title, msg) { appToast.show(title, msg) }
    }
    // ==========================================
    // S2-T16: GLOBAL KEYBOARD SHORTCUTS
    // ==========================================
    Shortcut {
        objectName: "shortcutOpenSrt"
        sequence: "Ctrl+O"
        enabled: !batchController.executionLocked
        onActivated: {
            if (!batchController.executionLocked) importSrtDialog.open()
        }
    }

    Shortcut {
        objectName: "shortcutOpenProject"
        sequence: "Ctrl+Shift+O"
        enabled: !batchController.executionLocked
        onActivated: {
            if (!batchController.executionLocked) loadProjectDialog.open()
        }
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

    FramelessResizeOverlay {
        anchors.fill: parent
    }

    Shortcut {
        sequence: "Ctrl+Alt+R"
        context: Qt.ApplicationShortcut
        onActivated: {
            mainWindow.responsiveTestToolsEnabled = !mainWindow.responsiveTestToolsEnabled
            responsiveTestToolbar.dismissed = false
        }
    }

    ResponsiveTestToolbar {
        id: responsiveTestToolbar
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: Theme.spaceMedium
        anchors.bottomMargin: Theme.spaceMedium
        toolVisible: mainWindow.responsiveTestToolsEnabled
        onDismissRequested: mainWindow.responsiveTestToolsEnabled = false
    }
}
