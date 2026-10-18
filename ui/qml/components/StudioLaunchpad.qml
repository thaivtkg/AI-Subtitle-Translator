import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Shapes 1.15
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
                if (url.endsWith(".srt") || url.endsWith(".aisrt") || url.endsWith(".mp4")) {
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

    // MAIN CONTENT CENTERED IN VIEW (100% MATCHING DESIGN MOCKUP)
    ColumnLayout {
        id: centerContent
        anchors.centerIn: parent
        width: Math.min(launchpadRoot.width * 0.90, 680)
        spacing: 16

        // 1. TOP CIRCULAR ICON (BLUE-PURPLE GRADIENT WITH WHITE ARROW ⤓)
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 72
            height: 72
            radius: 36
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#6366F1" }
                GradientStop { position: 1.0; color: "#A855F7" }
            }
            border.color: "#FFFFFF"
            border.width: 2.5

            Text {
                anchors.centerIn: parent
                text: "⤓"
                font.pixelSize: 32
                font.bold: true
                color: "#FFFFFF"
            }
        }

        // 2. HERO HEADINGS (BOLD WHITE TITLE + CRISP TRANSLUCENT SUBTITLE)
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: "AI Subtitle Studio"
                color: "#FFFFFF"
                font.pixelSize: 26
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                Layout.fillWidth: true
                text: "Kéo thả phụ đề hoặc video vào đây để bắt đầu dịch thuật với AI tự động phân tích ngữ cảnh"
                color: Qt.rgba(1.0, 1.0, 1.0, 0.88)
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Item { Layout.preferredHeight: 4 }

        // 3. DASHED TRANSLUCENT UPLOAD BOX (ROUNDED FROSTED CARD)
        Rectangle {
            id: dropZoneBox
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(centerContent.width, 580)
            Layout.preferredHeight: 175
            radius: 20
            color: dropArea.containsDrag ? Qt.rgba(1.0, 1.0, 1.0, 0.55) : Qt.rgba(1.0, 1.0, 1.0, 0.38)
            border.color: "transparent"
            border.width: 0
            clip: true

            Behavior on color { ColorAnimation { duration: 150 } }

            Shape {
                anchors.fill: parent
                layer.enabled: true
                layer.samples: 4
                ShapePath {
                    strokeColor: dropArea.containsDrag ? Theme.accentSapphire : Qt.rgba(1.0, 1.0, 1.0, 0.90)
                    strokeWidth: 2
                    strokeStyle: ShapePath.DashLine
                    dashPattern: [5, 4]
                    fillColor: "transparent"
                    startX: 20; startY: 0
                    PathLine { x: dropZoneBox.width - 20; y: 0 }
                    PathArc { x: dropZoneBox.width; y: 20; radiusX: 20; radiusY: 20 }
                    PathLine { x: dropZoneBox.width; y: dropZoneBox.height - 20 }
                    PathArc { x: dropZoneBox.width - 20; y: dropZoneBox.height; radiusX: 20; radiusY: 20 }
                    PathLine { x: 20; y: dropZoneBox.height }
                    PathArc { x: 0; y: dropZoneBox.height - 20; radiusX: 20; radiusY: 20 }
                    PathLine { x: 0; y: 20 }
                    PathArc { x: 20; y: 0; radiusX: 20; radiusY: 20 }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "📁"
                    font.pixelSize: 36
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: dropArea.containsDrag ? "Thả tệp vào đây ngay!" : "Kéo thả file vào đây hoặc Click để nạp dữ liệu mẫu"
                    font.pixelSize: 14
                    font.bold: true
                    color: "#0F172A"
                }

                // Extension format pills (.SRT, .AISRT, .MP4)
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8

                    Rectangle {
                        implicitWidth: 46
                        implicitHeight: 22
                        radius: 6
                        color: Qt.rgba(0.0, 0.4, 1.0, 0.12)
                        Text { anchors.centerIn: parent; text: ".SRT"; color: "#0066FF"; font.pixelSize: 11; font.bold: true }
                    }
                    Rectangle {
                        implicitWidth: 56
                        implicitHeight: 22
                        radius: 6
                        color: Qt.rgba(0.0, 0.4, 1.0, 0.12)
                        Text { anchors.centerIn: parent; text: ".AISRT"; color: "#0066FF"; font.pixelSize: 11; font.bold: true }
                    }
                    Rectangle {
                        implicitWidth: 48
                        implicitHeight: 22
                        radius: 6
                        color: Qt.rgba(0.0, 0.4, 1.0, 0.12)
                        Text { anchors.centerIn: parent; text: ".MP4"; color: "#0066FF"; font.pixelSize: 11; font.bold: true }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: launchpadRoot.openSrtClicked()
            }
        }

        Item { Layout.preferredHeight: 4 }

        // 4. ACTION BUTTONS ROW (EXACT MATCHING DESIGN)
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16

            // Button 1: ✨ Mở Dự Án Mẫu (Demo)
            Button {
                id: btnDemoProject
                implicitWidth: 210
                implicitHeight: 42
                contentItem: Text {
                    text: "✨ Mở Dự Án Mẫu (Demo)"
                    color: "#FFFFFF"
                    font.pixelSize: 13
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 21
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: btnDemoProject.pressed ? "#0052CC" : (btnDemoProject.hovered ? "#1A75FF" : "#0066FF") }
                        GradientStop { position: 1.0; color: btnDemoProject.pressed ? "#026AA2" : (btnDemoProject.hovered ? "#0EA5E9" : "#0284C7") }
                    }
                    border.color: Qt.rgba(1.0, 1.0, 1.0, 0.85)
                    border.width: 1
                }
                onClicked: {
                    if (typeof projectController !== "undefined" && typeof projectController.loadSampleProject === "function") {
                        projectController.loadSampleProject()
                    } else {
                        launchpadRoot.openSrtClicked()
                    }
                }
            }

            // Button 2: 📁 Chọn File Từ Máy Tính
            Button {
                id: btnBrowseFile
                implicitWidth: 200
                implicitHeight: 42
                contentItem: Text {
                    text: "📁 Chọn File Từ Máy Tính"
                    color: "#0F172A"
                    font.pixelSize: 13
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 21
                    color: btnBrowseFile.pressed ? Qt.rgba(1.0, 1.0, 1.0, 0.65) : (btnBrowseFile.hovered ? Qt.rgba(1.0, 1.0, 1.0, 0.90) : Qt.rgba(1.0, 1.0, 1.0, 0.78))
                    border.color: Qt.rgba(1.0, 1.0, 1.0, 0.95)
                    border.width: 1
                }
                onClicked: launchpadRoot.openSrtClicked()
            }
        }
    }
}
