import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
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

    // MAIN CONTENT CENTERED IN VIEW (100% MATCHING DESIGN MOCKUP)
    ColumnLayout {
        id: centerContent
        anchors.centerIn: parent
        width: Math.min(launchpadRoot.width * 0.90, 680)
        spacing: 16

        // 1. TOP CIRCULAR ICON (BLUE-PURPLE GRADIENT WITH WHITE ARROW ⤓)
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 68
            Layout.preferredHeight: 68
            width: 68
            height: 68

            Rectangle {
                anchors.centerIn: parent
                width: 68
                height: 68
                radius: 34
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#6366F1" }
                    GradientStop { position: 1.0; color: "#A855F7" }
                }
                border.color: "#FFFFFF"
                border.width: 2.5

                Canvas {
                    anchors.fill: parent
                    renderTarget: Canvas.FramebufferObject
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.strokeStyle = "#FFFFFF";
                        ctx.lineWidth = 3;
                        ctx.lineCap = "round";
                        ctx.lineJoin = "round";

                        var cx = width / 2;
                        var cy = height / 2;

                        // Downward arrow stem: (cx, cy - 12) -> (cx, cy + 4)
                        ctx.beginPath();
                        ctx.moveTo(cx, cy - 12);
                        ctx.lineTo(cx, cy + 4);
                        ctx.stroke();

                        // Downward arrow head: (cx - 7, cy - 3) -> (cx, cy + 4) -> (cx + 7, cy - 3)
                        ctx.beginPath();
                        ctx.moveTo(cx - 7, cy - 3);
                        ctx.lineTo(cx, cy + 4);
                        ctx.lineTo(cx + 7, cy - 3);
                        ctx.stroke();

                        // Bottom tray: (cx - 10, cy + 12) -> (cx + 10, cy + 12)
                        ctx.beginPath();
                        ctx.moveTo(cx - 10, cy + 12);
                        ctx.lineTo(cx + 10, cy + 12);
                        ctx.stroke();
                    }
                }
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

        // 3. TRANSLUCENT UPLOAD BOX (ROUNDED FROSTED CARD)
        Rectangle {
            id: dropZoneBox
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(centerContent.width, 580)
            Layout.preferredHeight: 175
            radius: 20

            readonly property bool isHoveredOrDragged: dropArea.containsDrag || dropZoneMouse.containsMouse

            // 1. Nền kính bừng sáng mượt mà khi hover (Khớp CSS .drop-target-pod:hover)
            color: isHoveredOrDragged ? Qt.rgba(1.0, 1.0, 1.0, 0.75) : Qt.rgba(1.0, 1.0, 1.0, 0.45)
            Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }

            // 2. Viền gương chuyển dần sang viền Sapphire phát quang
            border.color: isHoveredOrDragged ? Theme.accentSapphire : Theme.glassBorderSpecularUpper
            border.width: isHoveredOrDragged ? 2.0 : 1.5
            Behavior on border.color { ColorAnimation { duration: 200 } }

            // 3. Hiệu ứng nhấc bổng 2px (translateY -2px) như bản web mẫu
            transform: Translate {
                y: dropZoneBox.isHoveredOrDragged ? -2 : 0
                Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }

            // 4. Bóng quang học Sapphire tỏa khối 3D (Deep Optical Glow)
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: dropZoneBox.isHoveredOrDragged ? Qt.rgba(0.0, 0.40, 1.0, 0.35) : Qt.rgba(0.08, 0.04, 0.22, 0.12)
                shadowBlur: dropZoneBox.isHoveredOrDragged ? 0.65 : 0.42
                shadowVerticalOffset: dropZoneBox.isHoveredOrDragged ? 6 : 3
                Behavior on shadowColor { ColorAnimation { duration: 200 } }
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
                    text: dropArea.containsDrag ? "Thả tệp vào đây ngay!" : "Kéo thả file vào đây hoặc Click để nạp phụ đề"
                    font.pixelSize: 14
                    font.bold: true
                    color: Theme.textOnLightPod
                }

                // Extension format pills: .SRT và .AISRT
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
                }
            }

            MouseArea {
                id: dropZoneMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: launchpadRoot.openSrtClicked()
            }
        }
    }
}
