import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Item {
    id: launchpadRoot

    signal openSrtClicked()
    signal openProjectClicked()

    DropArea {
        id: dropArea
        anchors.fill: parent

        onEntered: (drag) => {
            if (!drag.hasUrls) {
                drag.accepted = false
                return
            }
            var hasValid = false
            for (var i = 0; i < drag.urls.length; i++) {
                var url = drag.urls[i].toString().toLowerCase()
                if (url.endsWith(".srt") || url.endsWith(".aisrt")) {
                    hasValid = true
                    break
                }
            }
            drag.accepted = hasValid
        }

        onDropped: (drop) => {
            if (drop.hasUrls && drop.urls.length > 0) {
                for (var i = 0; i < drop.urls.length; i++) {
                    var urlStr = drop.urls[i].toString()
                    var lower = urlStr.toLowerCase()
                    if (lower.endsWith(".srt")) {
                        if (typeof projectController !== "undefined") {
                            projectController.importSrt(urlStr)
                        }
                        break
                    } else if (lower.endsWith(".aisrt")) {
                        if (typeof projectController !== "undefined") {
                            projectController.loadProject(urlStr)
                        }
                        break
                    }
                }
            }
        }
    }

    Rectangle {
        id: dropCard
        anchors.centerIn: parent
        width: Math.min(launchpadRoot.width * 0.88, 640)
        implicitHeight: cardLayout.implicitHeight + Theme.spaceXl * 2
        radius: 16
        color: dropArea.containsDrag
               ? Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.08)
               : Theme.bgSurfaceElevated
        border.color: dropArea.containsDrag ? Theme.accentCyan : Theme.border
        border.width: dropArea.containsDrag ? 2 : 1

        Behavior on color { ColorAnimation { duration: Theme.animHover; easing.type: Easing.OutQuad } }
        Behavior on border.color { ColorAnimation { duration: Theme.animHover; easing.type: Easing.OutQuad } }

        ColumnLayout {
            id: cardLayout
            anchors.centerIn: parent
            width: parent.width - Theme.spaceXl * 2
            spacing: Theme.spaceMedium

            // Modern Icon Badge
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 68
                height: 68
                radius: 34
                color: dropArea.containsDrag
                       ? Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.2)
                       : Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.1)
                border.color: Theme.accentCyan
                border.width: 1

                Behavior on color { ColorAnimation { duration: Theme.animHover; easing.type: Easing.OutQuad } }

                Text {
                    anchors.centerIn: parent
                    text: dropArea.containsDrag ? "📥" : "⤓"
                    font.pixelSize: dropArea.containsDrag ? 32 : 30
                    font.bold: true
                    color: Theme.accentCyan
                }
            }

            // Headings
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.spaceXs

                Text {
                    Layout.fillWidth: true
                    text: dropArea.containsDrag ? "Thả tệp vào đây để mở ngay lập tức" : "Kéo & thả file phụ đề vào đây"
                    color: Theme.textPrimary
                    font.pixelSize: 20
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    Layout.fillWidth: true
                    text: "Hỗ trợ tệp phụ đề gốc (.srt) và tệp dự án hoàn chỉnh (.aisrt)"
                    color: Theme.textMuted
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // Action Buttons
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Theme.spaceSmall
                spacing: Theme.spaceMedium

                ColumnLayout {
                    spacing: Theme.spaceXs
                    Layout.alignment: Qt.AlignHCenter

                    AppButton {
                        text: "⚡ Mở file SRT"
                        isPrimary: true
                        tooltip: "Mở file phụ đề SRT — Ctrl + O"
                        Layout.preferredWidth: 160
                        Layout.preferredHeight: 38
                        onClicked: launchpadRoot.openSrtClicked()
                    }
                    Text {
                        text: "Ctrl + O"
                        color: Theme.textDisabled
                        font.pixelSize: 11
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                ColumnLayout {
                    spacing: Theme.spaceXs
                    Layout.alignment: Qt.AlignHCenter

                    AppButton {
                        text: "◈ Mở dự án"
                        tooltip: "Mở file dự án .aisrt — Ctrl + Shift + O"
                        Layout.preferredWidth: 160
                        Layout.preferredHeight: 38
                        onClicked: launchpadRoot.openProjectClicked()
                    }
                    Text {
                        text: "Ctrl + Shift + O"
                        color: Theme.textDisabled
                        font.pixelSize: 11
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: Theme.spaceSmall
                height: 1
                color: Theme.border
                opacity: 0.6
            }

            // Feature Badges
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.spaceSmall

                Item { Layout.fillWidth: true }

                Rectangle {
                    height: 24
                    implicitWidth: b1.implicitWidth + 16
                    radius: 12
                    color: Theme.bgSurface
                    border.color: Theme.border
                    border.width: 1
                    Text { id: b1; anchors.centerIn: parent; text: "✦ Smart Context LLM"; color: Theme.textSecondary; font.pixelSize: 11 }
                }

                Rectangle {
                    height: 24
                    implicitWidth: b2.implicitWidth + 16
                    radius: 12
                    color: Theme.bgSurface
                    border.color: Theme.border
                    border.width: 1
                    Text { id: b2; anchors.centerIn: parent; text: "🛡️ QA Guard (CPS/CPL)"; color: Theme.textSecondary; font.pixelSize: 11 }
                }

                Rectangle {
                    height: 24
                    implicitWidth: b3.implicitWidth + 16
                    radius: 12
                    color: Theme.bgSurface
                    border.color: Theme.border
                    border.width: 1
                    Text { id: b3; anchors.centerIn: parent; text: "🧠 Translation Memory"; color: Theme.textSecondary; font.pixelSize: 11 }
                }

                Rectangle {
                    height: 24
                    implicitWidth: b4.implicitWidth + 16
                    radius: 12
                    color: Theme.bgSurface
                    border.color: Theme.border
                    border.width: 1
                    Text { id: b4; anchors.centerIn: parent; text: "📖 Entity Dict"; color: Theme.textSecondary; font.pixelSize: 11 }
                }

                Item { Layout.fillWidth: true }
            }
        }
    }
}
