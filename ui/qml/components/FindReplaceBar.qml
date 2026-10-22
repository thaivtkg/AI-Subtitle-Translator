import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import "../theme"

Rectangle {
    id: root
    implicitHeight: mainCol.implicitHeight + 16
    radius: 12
    color: Qt.rgba(0.97, 0.98, 1.0, 0.95)
    border.color: Theme.accentSapphire
    border.width: 1.5

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowBlur: 0.5
        shadowColor: Qt.rgba(0.0, 0.2, 0.5, 0.22)
        shadowVerticalOffset: 3
    }

    signal closeRequested()

    property string findText: findInput.text
    property string replaceText: replaceInput.text
    property string scope: scopeCombo.currentIndex === 1 ? "TRANSLATION" : (scopeCombo.currentIndex === 2 ? "ORIGINAL" : "ALL")
    property bool matchCase: chkMatchCase.checked
    property bool wholeWord: chkWholeWord.checked
    property bool isRegex: chkRegex.checked
    property bool addToGlossary: chkGlossary.checked
    property string statusMessage: ""

    function focusFind() {
        findInput.forceActiveFocus()
        findInput.selectAll()
    }

    function doPreview() {
        if (!findInput.text.trim()) {
            statusMessage = "Vui lòng nhập từ khóa tìm kiếm"
            return
        }
        if (typeof projectController !== "undefined") {
            var res = projectController.previewFindReplace(
                findInput.text,
                root.scope,
                root.matchCase,
                root.wholeWord,
                root.isRegex
            )
            if (res.error) {
                statusMessage = "⚠️ " + res.error
            } else {
                statusMessage = "Tìm thấy " + res.total_matches + " kết quả (" + res.affected_rows.length + " câu)"
            }
        }
    }

    function doReplaceAll() {
        if (!findInput.text.trim()) {
            statusMessage = "Vui lòng nhập từ khóa tìm kiếm"
            return
        }
        if (typeof projectController !== "undefined") {
            var count = projectController.executeFindReplace(
                findInput.text,
                replaceInput.text,
                root.scope,
                root.matchCase,
                root.wholeWord,
                root.isRegex,
                root.addToGlossary
            )
            statusMessage = "Đã thay thế " + count + " vị trí"
        }
    }

    ColumnLayout {
        id: mainCol
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // Row 1: Inputs & Action buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "🔍"
                font.pixelSize: 13
            }

            TextField {
                id: findInput
                objectName: "findReplaceFindInput"
                Layout.fillWidth: true
                Layout.minimumWidth: 110
                placeholderText: "Tìm kiếm..."
                font.pixelSize: 11
                color: Theme.textOnLightPod
                background: Rectangle {
                    radius: 6
                    color: "#FFFFFF"
                    border.color: findInput.activeFocus ? Theme.accentSapphire : "#CBD5E1"
                    border.width: 1
                }
                onAccepted: root.doPreview()
            }

            Text {
                text: "➔"
                color: Theme.textSecondary
                font.pixelSize: 12
            }

            TextField {
                id: replaceInput
                objectName: "findReplaceReplaceInput"
                Layout.fillWidth: true
                Layout.minimumWidth: 110
                placeholderText: "Thay thế bằng..."
                font.pixelSize: 11
                color: Theme.textOnLightPod
                background: Rectangle {
                    radius: 6
                    color: "#FFFFFF"
                    border.color: replaceInput.activeFocus ? Theme.accentSapphire : "#CBD5E1"
                    border.width: 1
                }
                onAccepted: root.doReplaceAll()
            }

            ComboBox {
                id: scopeCombo
                implicitWidth: 105
                implicitHeight: 28
                model: ["Tất cả", "Bản dịch", "Câu gốc"]
                font.pixelSize: 11
                background: Rectangle {
                    radius: 6
                    color: "#FFFFFF"
                    border.color: "#CBD5E1"
                    border.width: 1
                }
            }

            Button {
                id: btnPreview
                objectName: "btnFindPreview"
                text: "Tìm"
                implicitHeight: 28
                implicitWidth: 50
                contentItem: Text {
                    text: "Tìm"
                    color: Theme.accentSapphire
                    font.pixelSize: 11
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 6
                    color: btnPreview.hovered ? Qt.rgba(0.0, 0.45, 1.0, 0.15) : Qt.rgba(0.0, 0.45, 1.0, 0.08)
                    border.color: Theme.accentSapphire
                    border.width: 1
                }
                onClicked: root.doPreview()
            }

            Button {
                id: btnReplace
                objectName: "btnFindReplaceAll"
                text: "Thay thế"
                implicitHeight: 28
                implicitWidth: 76
                contentItem: Text {
                    text: "Thay thế"
                    color: "#FFFFFF"
                    font.pixelSize: 11
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 6
                    color: Theme.accentSapphire
                }
                onClicked: root.doReplaceAll()
            }

            Button {
                id: btnClose
                implicitWidth: 26
                implicitHeight: 26
                contentItem: Text {
                    text: "✕"
                    color: "#64748B"
                    font.pixelSize: 12
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 13
                    color: btnClose.hovered ? "#F1F5F9" : "transparent"
                }
                onClicked: root.closeRequested()
            }
        }

        // Row 2: Checkbox options & Feedback status
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            CheckBox {
                id: chkMatchCase
                text: "Hoa/thường"
                font.pixelSize: 10
            }

            CheckBox {
                id: chkWholeWord
                text: "Toàn bộ từ"
                font.pixelSize: 10
            }

            CheckBox {
                id: chkRegex
                text: "Regex"
                font.pixelSize: 10
            }

            CheckBox {
                id: chkGlossary
                text: "📌 Ghim vào Glossary"
                font.pixelSize: 10
                checked: true
            }

            Item { Layout.fillWidth: true }

            Text {
                id: statusLbl
                text: root.statusMessage
                color: root.statusMessage.indexOf("⚠️") !== -1 ? Theme.danger : Theme.accentSapphire
                font.pixelSize: 11
                font.bold: true
            }
        }
    }
}
