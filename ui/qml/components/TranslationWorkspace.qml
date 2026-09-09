import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Item {
    id: workspace

    property bool hasSelection: false
    property int totalCount: 0
    signal translateRequested(string sourceLang)
    signal acceptRequested(string text)
    signal openSrtRequested()
    signal openProjectRequested()

    function setSourceLanguage(lang) { langSelector.setLanguage(lang) }
    function getSourceLanguage() { return langSelector.sourceLang }

    EmptyWorkspace {
        anchors.fill: parent
        visible: !workspace.hasSelection
        emptyStateMode: workspace.totalCount > 0 ? "no_selection" : "no_project"
        onOpenSrtClicked: workspace.openSrtRequested()
        onOpenProjectClicked: workspace.openProjectRequested()
    }

    ColumnLayout {
        anchors.fill: parent
        visible: workspace.hasSelection
        spacing: Theme.spaceMedium

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Theme.spaceSmall
            LanguageSelector { id: langSelector }
            Item { Layout.fillWidth: true }
            RowLayout {
                spacing: Theme.spaceSmall
                Text { text: "Status:"; color: Theme.textMuted; font.pixelSize: 12 }
                StatusBadge { status: translationController.status }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: workspace.height * 0.35
            spacing: Theme.spaceSmall
            RowLayout {
                Layout.fillWidth: true
                Text { text: "ORIGINAL"; color: Theme.textSecondary; font.pixelSize: 12; font.bold: true }
                Item { Layout.fillWidth: true }
                Text { text: langSelector.sourceLang.toUpperCase(); color: Theme.textMuted; font.pixelSize: 12; font.bold: true }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.bgSurface
                radius: Theme.radius
                ScrollView {
                    anchors.fill: parent
                    anchors.margins: Theme.spaceMedium
                    TextArea {
                        text: translationController.currentOriginal
                        color: Theme.textSecondary
                        font.pixelSize: 14
                        wrapMode: Text.WordWrap
                        readOnly: true
                        selectByMouse: true
                        background: null
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spaceSmall
            RowLayout {
                Layout.fillWidth: true
                Text { text: "VIETNAMESE"; color: Theme.textPrimary; font.pixelSize: 12; font.bold: true }
                Item { Layout.fillWidth: true }
                AIActivityIndicator {
                    active: translationController.status === "TRANSLATING"
                    color: Theme.accentCyan
                    Layout.alignment: Qt.AlignVCenter
                }
                Text {
                    text: {
                        const s = translationController.status
                        if (s === "TRANSLATING") return "Translating…"
                        if (s === "ERROR") return "ERROR ✕"
                        if (s === "ACCEPTED") return "[ ACCEPTED ]"
                        if (s === "EDITED") return "EDITED ●"
                        if (s === "TRANSLATED") return "TRANSLATED ✦"
                        return "PENDING"
                    }
                    color: translationController.status === "ACCEPTED" ? Theme.success : translationController.status === "ERROR" ? Theme.danger : translationController.status === "TRANSLATED" || translationController.status === "EDITED" ? Theme.accentPurple : Theme.textMuted
                    font.pixelSize: 12
                    font.bold: true
                }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.bgSurfaceElevated
                radius: Theme.radius
                border.color: translationController.status === "ERROR" ? Theme.danger : translationInput.activeFocus ? Theme.accentCyan : Theme.border
                border.width: translationInput.activeFocus || translationController.status === "ERROR" ? 2 : 1
                Behavior on border.color { ColorAnimation { duration: 100 } }
                ScrollView {
                    anchors.fill: parent
                    anchors.margins: Theme.spaceMedium
                    TextArea {
                        id: translationInput
                        text: translationController.currentTranslation || (translationController.status === "TRANSLATING" ? "Generating translation..." : "")
                        color: translationController.status === "TRANSLATING" && translationController.currentTranslation === "" ? Theme.textMuted : Theme.textPrimary
                        font.pixelSize: 18
                        wrapMode: Text.WordWrap
                        selectByMouse: true
                        readOnly: translationController.status === "TRANSLATING"
                        background: null
                        onTextChanged: {
                            if (translationInput.focus && translationController.status !== "TRANSLATING" && translationInput.text !== translationController.currentTranslation)
                                translationController.markAsEdited()
                        }
                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Return && (event.modifiers & Qt.ControlModifier)) {
                                event.accepted = true
                                if (translationController.status === "TRANSLATED" || translationController.status === "EDITED")
                                    acceptRequested(translationInput.text)
                            }
                        }
                    }
                }
            }
            Text {
                visible: translationController.status === "ERROR"
                text: "Translation failed. Model inference error."
                color: Theme.danger
                font.pixelSize: 12
                Layout.fillWidth: true
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            Layout.topMargin: Theme.spaceSmall
            Layout.bottomMargin: Theme.spaceSmall
            spacing: Theme.spaceSmall
            AppButton {
                text: "Retry"
                enabled: ["ERROR", "TRANSLATED", "EDITED", "ACCEPTED"].indexOf(translationController.status) >= 0
                onClicked: translateRequested(langSelector.sourceLang)
            }
            AppButton {
                text: translationController.status === "TRANSLATING" ? "◌ Translating..." : "Translate"
                isPrimary: true
                enabled: translationController.status !== "TRANSLATING"
                onClicked: translateRequested(langSelector.sourceLang)
            }
            AppButton {
                text: "Accept"
                enabled: translationController.status === "TRANSLATED" || translationController.status === "EDITED"
                onClicked: acceptRequested(translationInput.text)
            }
        }
    }
}
