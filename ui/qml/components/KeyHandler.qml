import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: keyHandler
    
    // ============================================
    // KEYBOARD SHORTCUTS (S2-E T16)
    // ============================================
    
    property var mainWindow: null
    property var translationController: null
    property var projectController: null
    
    Keys.onPressed: {
        if (event === Qt.Key_Return && event.modifiers & Qt.ControlModifier) {
            acceptCurrentSubtitle()
            return
        }
        
        if (event.key === "Left") {
            previousSubtitle()
            return
        }
        
        if (event.key === "Right") {
            nextSubtitle()
            return
        }
        
        if (event.key === "r" || event.key === "R") {
            retryCurrentSubtitle()
            return
        }
        
        if (event.modifiers & Qt.ControlModifier) {
            switch (event.key) {
                case Qt.Key_O:  // Ctrl+O = Open SRT/Project
                    openSrtOrProject()
                    break
                case Qt.Key_S:  // Ctrl+S = Save project
                    saveCurrentSubtitle()
                    break
                case Qt.Key_Shift:  // Ctrl+Shift+S = Export SRT
                    exportSrt()
                    break
            }
        } else if (event.modifiers & Qt.ShiftModifier) {
            switch (event.key) {
                case Qt.Key_Escape:  // Esc = Cancel translation
                    cancelCurrentSubtitle()
                    break
            }
        } else if (!event.isAutoRepeat && event.modifiers === Qt.NoModifier) {
            switch (event.key) {
                case Qt.Key_Space:  // Space = AI Translate
                    translateCurrentSubtitle()
                    break
                case Qt.Key_Return:  // Enter = Accept subtitle
                    acceptCurrentSubtitle()
                    break
            }
        }
    }

    function previousSubtitle() {
        if (mainWindow.subtitleModel && mainWindow.subtitleModel.count > 0) {
            const currentIndex = mainWindow.subtitleListModel.currentIndex
            if (currentIndex > 0) {
                mainWindow.subtitleListModel.currentIndex -= 1
            }
        }
    }

    function nextSubtitle() {
        if (mainWindow.subtitleModel && mainWindow.subtitleModel.count > 0) {
            const currentIndex = mainWindow.subtitleListModel.currentIndex
            if (currentIndex >= 0 && currentIndex < mainWindow.subtitleModel.count - 1) {
                mainWindow.subtitleListModel.currentIndex += 1
            }
        }
    }

    function acceptCurrentSubtitle() {
        if (translationController && translationController.status === "TRANSLATED") {
            translationController.acceptCurrentTranslation()
        } else if (translationController && translationController.status === "EDITED") {
            translationController.acceptEditedTranslation()
        }
    }

    function retryCurrentSubtitle() {
        if (translationController) {
            translationController.retryCurrentTranslation()
        }
    }

    function translateCurrentSubtitle() {
        if (translationController && mainWindow.subtitleModel && mainWindow.subtitleModel.count > 0) {
            const currentIndex = mainWindow.subtitleListModel.currentIndex
            if (currentIndex >= 0) {
                translationController.translateSubtitle(currentIndex)
            }
        }
    }

    function cancelCurrentSubtitle() {
        if (translationController) {
            translationController.cancelCurrentTranslation()
        }
    }

    function saveCurrentSubtitle() {
        if (projectController && mainWindow.subtitleModel && mainWindow.subtitleModel.count > 0) {
            const currentIndex = mainWindow.subtitleListModel.currentIndex
            if (currentIndex >= 0) {
                projectController.saveSubtitle(currentIndex, 
                    translationWorkspace.translationInput.text || "",
                    sourceLanguage, targetLanguage
                )
            }
        }
    }

    function exportSrt() {
        if (projectController) {
            projectController.exportSrt()
        }
    }

    function openSrtOrProject() {
        const lastAction = mainWindow.lastOpenType || "srt"
        if (lastAction === "project") {
            loadProjectDialog.open()
        } else {
            importSrtDialog.open()
        }
    }

    // ============================================
    // EXPOSED PROPERTIES FOR MAIN WINDOW BINDING
    // ============================================
    
    property bool isAcceptEnabled: translationController && 
                                    (translationController.status === "TRANSLATED" || 
                                     translationController.status === "EDITED")
    
    property bool isRetryEnabled: translationController && 
                                   translationController.status !== "TRANSLATING"
    
    property bool isTranslateEnabled: mainWindow.subtitleModel && 
                                      mainWindow.subtitleModel.count > 0 &&
                                      !translationController.isBusy
    
    property bool isPreviousEnabled: mainWindow.subtitleModel && 
                                       mainWindow.subtitleModel.count > 0 &&
                                       mainWindow.subtitleListModel.currentIndex > 0
    
    property bool isNextEnabled: mainWindow.subtitleModel && 
                                   mainWindow.subtitleModel.count > 0 &&
                                   mainWindow.subtitleListModel.currentIndex < mainWindow.subtitleModel.count - 1
}
