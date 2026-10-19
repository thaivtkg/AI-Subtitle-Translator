import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Item {
    id: root
    implicitHeight: 32

    property int acceptedCount: 0
    property int totalCount: 0
    property string engineStatus: "Not loaded"
    property real vramUsed: -1.0
    property real vramTotal: -1.0
    property string gpuName: ""
    property string backendStatus: ""
    readonly property bool compactMode: width < 1150

    property real progressRatio: totalCount > 0 ? acceptedCount / totalCount : 0
    property int progressPercent: Math.round(progressRatio * 100)

    // Seamless Bottom Bar
    Rectangle {
        id: capsuleBar
        anchors.fill: parent
        radius: 0
        color: Theme.glassIslandSurface
        border.color: "transparent"

        // Top 1px glass divider line
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Theme.glassBorderSubtle
            antialiasing: false
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12

            // LEFT SIDE: Status & GPU / Progress
            RowLayout {
                spacing: 8

                // Engine / Readiness Indicator
                RowLayout {
                    spacing: 6
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: "#22C55E" // Neon emerald
                    }

                    Text {
                        objectName: "engineStatusText"
                        id: engineText
                        text: root.engineStatus === "Ready" || root.engineStatus === "Not loaded" ? "• Sẵn sàng" : ("• " + root.engineStatus)
                        color: "#22C55E"
                        font.pixelSize: 11
                        font.bold: true
                    }

                    Text {
                        text: "|"
                        color: Qt.rgba(1, 1, 1, 0.4)
                        font.pixelSize: 11
                    }

                    Text {
                        text: {
                            if (root.gpuName !== "" && root.gpuName !== "Unknown") {
                                var shortGpu = root.gpuName.replace("NVIDIA GeForce ", "").replace("AMD Radeon ", "")
                                return "GPU: " + shortGpu + (root.backendStatus !== "" ? (" (" + root.backendStatus + ")") : "")
                            }
                            return root.backendStatus !== "" ? ("Bộ tăng tốc: " + root.backendStatus) : "GPU: Tự động phát hiện"
                        }
                        color: Qt.rgba(1, 1, 1, 0.85)
                        font.pixelSize: 11
                        font.bold: true
                    }
                }

                Text {
                    visible: root.totalCount > 0
                    text: "|"
                    color: Qt.rgba(1, 1, 1, 0.4)
                    font.pixelSize: 11
                }

                // Progress Info if project active
                Text {
                    objectName: "statusProgressText"
                    id: progressText
                    visible: true
                    text: root.totalCount > 0 
                          ? ("✓ " + root.acceptedCount + " / " + root.totalCount + " Đã duyệt (" + root.progressPercent + "%)")
                          : "Chưa mở dự án"
                    color: Qt.rgba(1, 1, 1, 0.85)
                    font.pixelSize: 11
                    font.bold: true
                }
            }

            Item { Layout.fillWidth: true }

            // RIGHT SIDE: VRAM & FPS
            RowLayout {
                spacing: 12

                FrameAnimation {
                    id: frameAnim
                    running: true
                }

                Timer {
                    id: fpsSampler
                    interval: 500
                    running: true
                    repeat: true
                    onTriggered: {
                        if (frameAnim.smoothFrameTime > 0) {
                            var liveFps = 1.0 / frameAnim.smoothFrameTime
                            fpsText.text = "FPS: " + liveFps.toFixed(1)
                        }
                    }
                }

                Text {
                    objectName: "vramStatusText"
                    id: vramText
                    text: (root.vramTotal > 0 && root.vramUsed >= 0)
                          ? ("Bộ nhớ VRAM: " + root.vramUsed.toFixed(1) + " / " + root.vramTotal.toFixed(1) + " GB")
                          : (root.vramTotal > 0
                             ? ("Bộ nhớ VRAM: " + root.vramTotal.toFixed(1) + " GB")
                             : "Bộ nhớ: RAM hệ thống")
                    color: Qt.rgba(1, 1, 1, 0.85)
                    font.pixelSize: 11
                    font.bold: true
                }

                Text {
                    id: fpsText
                    text: "FPS: 60.0"
                    color: Qt.rgba(1, 1, 1, 0.85)
                    font.pixelSize: 11
                    font.bold: true
                }
            }
        }
    }
}
