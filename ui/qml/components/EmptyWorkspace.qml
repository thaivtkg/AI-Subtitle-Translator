import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Item {
    id: root
    property string emptyStateMode: "no_project"
    signal openSrtClicked()
    signal openProjectClicked()

    DropArea {
        id: dropArea
        anchors.fill: parent
        enabled: root.emptyStateMode === "no_project"

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
        width: Math.min(parent.width * 0.85, 460)
        implicitHeight: cardContent.implicitHeight + Theme.spaceLarge * 2
        radius: Theme.radius * 2
        color: root.emptyStateMode === "no_project" && dropArea.containsDrag
               ? Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.08)
               : Theme.bgSurface
        border.color: root.emptyStateMode === "no_project" && dropArea.containsDrag
                      ? Theme.accentCyan
                      : Theme.border
        border.width: root.emptyStateMode === "no_project" && dropArea.containsDrag ? 2 : 1

        Behavior on color { ColorAnimation { duration: Theme.animHover; easing.type: Easing.OutQuad } }
        Behavior on border.color { ColorAnimation { duration: Theme.animHover; easing.type: Easing.OutQuad } }

        ColumnLayout {
            id: cardContent
            anchors.centerIn: parent
            width: parent.width - Theme.spaceLarge * 2
            spacing: Theme.spaceMedium

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.emptyStateMode === "no_project"
                      ? (dropArea.containsDrag ? "📥" : "📂")
                      : "🎯"
                font.pixelSize: 40
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.emptyStateMode === "no_project"
                      ? (dropArea.containsDrag ? "Thả tệp vào đây để mở" : "Chưa mở dự án phụ đề")
                      : "Chọn một câu phụ đề"
                color: Theme.textPrimary
                font.pixelSize: 18
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                text: root.emptyStateMode === "no_project"
                      ? (dropArea.containsDrag
                         ? "Nhả chuột để tải tệp .srt hoặc .aisrt ngay lập tức"
                         : "Kéo thả tệp .srt hoặc .aisrt vào đây, hoặc nhấn nút bên dưới để bắt đầu dịch thuật.")
                      : "Chọn một câu phụ đề từ danh sách bên trái để xem, chỉnh sửa hoặc dịch câu."
                color: Theme.textMuted
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                lineHeight: 1.3
            }

            RowLayout {
                visible: root.emptyStateMode === "no_project"
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Theme.spaceSmall
                spacing: Theme.spaceMedium

                AppButton {
                    text: "Mở file SRT"
                    isPrimary: true
                    onClicked: root.openSrtClicked()
                }
                AppButton {
                    text: "Mở file dự án"
                    onClicked: root.openProjectClicked()
                }
            }
        }
    }
}
