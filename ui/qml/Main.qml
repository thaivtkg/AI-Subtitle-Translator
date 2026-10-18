import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QtQuick.Dialogs
import QtQuick.Effects
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
    color: "transparent"

    // THÊM MỚI: Biến toàn cục hứng Story Summary (đặt ở cấp cao nhất)
    property string globalStorySummary: ""
    property var selectedSubtitleIndices: []
    // P2.5-T13-D0: manual responsive acceptance only.
    property bool responsiveTestToolsEnabled: Qt.application.arguments.indexOf("--dev-tools") >= 0

    // Mask for rounded liquid glass window frame
    Item {
        id: windowMaskContainer
        anchors.fill: windowRootContainer
        layer.enabled: true
        visible: false
        Rectangle {
            anchors.fill: parent
            radius: windowRootContainer.radius
            color: "white"
        }
    }

    // ==========================================
    // P2.5-T2: PROJECT HEADER
    // ==========================================
    // ==========================================
    // SEAMLESS LIQUID GLASS ROOT WINDOW CONTAINER (ROUNDED & LUMINOUS)
    // ==========================================
    Rectangle {
        id: windowRootContainer
        anchors.fill: parent
        anchors.margins: 0
        radius: (mainWindow.visibility === Window.Maximized) ? 0 : 16
        clip: true
        border.color: Qt.rgba(1.0, 1.0, 1.0, 0.75)
        border.width: 1.5
        layer.enabled: mainWindow.visibility !== Window.Maximized
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: windowMaskContainer
        }

        // LAYER 1: Fluid Liquid Mesh Wallpaper (100% 1:1 match with web design mockup)
        Image {
            id: bgLiquidMesh
            anchors.fill: parent
            source: "../assets/liquid_mesh_bg.jpg"
            fillMode: Image.PreserveAspectCrop
            smooth: true
            asynchronous: false
        }

        // LAYER 2: Ultra-Gloss Liquid Glass Frost Sheen
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Qt.rgba(1.0, 1.0, 1.0, 0.12) } // Giảm từ 0.28 xuống 0.12
                GradientStop { position: 0.5; color: Qt.rgba(1.0, 1.0, 1.0, 0.03) } // Giảm từ 0.12 xuống 0.03
                GradientStop { position: 1.0; color: Qt.rgba(1.0, 1.0, 1.0, 0.08) } // Giảm từ 0.20 xuống 0.08
            }
        }


        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            AppHeader {
                id: appHeader
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                projectName: "Workspace"
                hasProject: projectController.hasProject || subListView.count > 0
                isSaved: (projectController.hasProject || subListView.count > 0) && !projectController.isDirty
                hasProjectData: subListView.count > 0
                projectMutationLocked: batchController.executionLocked
                sourceLanguage: transWorkspace.getSourceLanguage()
                targetLanguage: "Vietnamese"
                storySummary: mainWindow.globalStorySummary
                currentSubtitleIndex: subListView.currentRawIndex
                selectedIndices: mainWindow.selectedSubtitleIndices
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

            StudioLaunchpad {
                id: studioLaunchpad
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: subListView.count === 0
                onOpenSrtClicked: {
                    if (!batchController.executionLocked) importSrtDialog.open()
                }
                onOpenProjectClicked: {
                    if (!batchController.executionLocked) loadProjectDialog.open()
                }
            }

            SplitView {
                id: mainSplitView
                objectName: "mainSplitView"
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: subListView.count > 0
                orientation: Qt.Horizontal
                handle: Rectangle {
                    implicitWidth: 1
                    color: Qt.rgba(1, 1, 1, 0.32) // Tăng từ 0.24 lên 0.32 cho sắc nét như bản mẫu
                }

                // PANEL 1: SUBTITLE NAVIGATOR (SEAMLESS DOCKED)
                Rectangle {
                    id: subtitleIsland
                    SplitView.preferredWidth: 320
                    SplitView.minimumWidth: 260
                    SplitView.maximumWidth: 450
                    radius: 0
                    color: Theme.glassIslandSurface
                    border.color: "transparent"
                    border.width: 0
                    clip: true

                    SubtitleListView {
                        id: subListView
                        anchors.fill: parent
                        anchors.margins: 0
                        model: typeof filteredSubtitleModel !== "undefined" && filteredSubtitleModel ? filteredSubtitleModel : subtitleModel
                        selectedIndices: mainWindow.selectedSubtitleIndices
                        onSelectionChanged: function(indices) {
                            mainWindow.selectedSubtitleIndices = indices
                        }
                    }
                }

                // PANEL 2: TRANSLATION WORKSPACE (SEAMLESS DOCKED)
                Rectangle {
                    id: workspaceIsland
                    SplitView.fillWidth: true
                    SplitView.minimumWidth: 400
                    radius: 0
                    color: Theme.glassIslandSurface
                    border.color: "transparent"
                    border.width: 0
                    clip: true

                    TranslationWorkspace {
                        id: transWorkspace
                        anchors.fill: parent
                        anchors.margins: Theme.spaceMedium
                        hasSelection: subListView.currentRawIndex >= 0
                        totalCount: subListView.count
                        executionLocked: batchController.executionLocked

                        onTranslateRequested: (sourceLang) => {
                            translationController.requestTranslation(subListView.currentRawIndex, sourceLang, "Vietnamese", globalStorySummary)
                        }

                        onAcceptRequested: (text) => {
                            let isSuccess = translationController.acceptTranslation(subListView.currentRawIndex, text)
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

                // PANEL 3: CONTEXT INSPECTOR (SEAMLESS DOCKED)
                Rectangle {
                    id: contextIsland
                    SplitView.preferredWidth: 300
                    SplitView.minimumWidth: 280
                    SplitView.maximumWidth: 400
                    radius: 0
                    color: Theme.glassIslandSurface
                    border.color: "transparent"
                    border.width: 0
                    clip: true

                    ContextInspector {
                        id: contextInspector
                        anchors.fill: parent
                        anchors.margins: Theme.spaceMedium
                    }
                }
            }

            AppStatusBar {
                id: appStatusBar
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                totalCount: translationController.totalSubtitleCount
                acceptedCount: translationController.acceptedCount
                engineStatus: {
                    return translationController.engineStatus
                }
                vramUsed: typeof translationController.vramUsed !== "undefined" ? translationController.vramUsed : -1.0
                vramTotal: typeof translationController.vramTotal !== "undefined" ? translationController.vramTotal : -1.0
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
