import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Item {
    id: workspace

    property bool hasSelection: false
    signal translateRequested(string sourceLang)
    signal acceptRequested(string text)

    function setSourceLanguage(lang) { langSelector.setLanguage(lang) }
    function getSourceLanguage() { return langSelector.sourceLang }

    Text {
        anchors.centerIn: parent
        visible: !workspace.hasSelection
        text: "Chọn một subtitle để bắt đầu dịch."
        color: Theme.textDisabled
        font.pixelSize: 16
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
            Layout.preferredHeight: workspace.height * 0.32
            spacing: Theme.spaceSmall
            Text { text: "ORIGINAL"; color: Theme.textSecondary; font.pixelSize: 12; font.bold: true; Layout.leftMargin: Theme.spaceXs }
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
                        font.pixelSize: 15
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
                Layout.leftMargin: Theme.spaceXs
                Layout.rightMargin: Theme.spaceXs
                Text { text: "TARGET TRANSLATION"; color: Theme.textPrimary; font.pixelSize: 12; font.bold: true }
                Item { Layout.fillWidth: true }
                Text { text: "EDITABLE ✎"; color: Theme.textMuted; font.pixelSize: 12 }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.bgSurfaceElevated
                radius: Theme.radius
                border.color: translationInput.activeFocus ? Theme.accentCyan : Theme.border
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 120 } }
                ScrollView {
                    anchors.fill: parent
                    anchors.margins: Theme.spaceMedium
                    TextArea {
                        id: translationInput
                        text: translationController.currentTranslation
                        color: Theme.textPrimary
                        font.pixelSize: 18
                        wrapMode: Text.WordWrap
                        selectByMouse: true
                        background: null
                        onTextChanged: {
                            if (translationInput.focus && translationController.status !== "TRANSLATING" && translationInput.text !== translationController.currentTranslation)
                                translationController.markAsEdited()
                        }
                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Return && (event.modifiers & Qt.ControlModifier)) {
                                event.accepted = true
                                if (["TRANSLATED", "EDITED", "ACCEPTED"].indexOf(translationController.status) >= 0)
                                    acceptRequested(translationInput.text)
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            Layout.bottomMargin: Theme.spaceSmall
            spacing: Theme.spaceSmall
            AppButton {
                text: "↻ Retry"
                enabled: translationController.status !== "TRANSLATING"
                onClicked: translateRequested(langSelector.sourceLang)
            }
            AppButton {
                text: translationController.status === "TRANSLATING" ? "◌ Translating..." : "✦ Translate"
                isPrimary: true
                enabled: translationController.status !== "TRANSLATING"
                onClicked: translateRequested(langSelector.sourceLang)
            }
            AppButton {
                text: "✓ Accept"
                enabled: ["TRANSLATED", "EDITED", "ACCEPTED"].indexOf(translationController.status) >= 0
                onClicked: acceptRequested(translationInput.text)
            }
        }
    }
}
