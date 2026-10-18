import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Item {
    id: root
    implicitHeight: 40

    property int acceptedCount: 0
    property int totalCount: 0
    property string engineStatus: "Not loaded"
    property real vramUsed: -1.0
    property real vramTotal: -1.0
    readonly property bool compactMode: width < 1150

    property real progressRatio: totalCount > 0 ? acceptedCount / totalCount : 0
    property int progressPercent: Math.round(progressRatio * 100)

    // Floating Translucent Capsule Bar
    Rectangle {
        id: capsuleBar
        anchors.fill: parent
        anchors.leftMargin: Theme.windowPadding
        anchors.rightMargin: Theme.windowPadding
        anchors.bottomMargin: 4
        anchors.topMargin: 2
        radius: Theme.radiusPill
        color: Theme.glassIslandSurface
        border.color: Theme.glassBorderSpecularUpper
        border.width: 1

        // Top specular gleam
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 1
            height: 1
            radius: parent.radius
            color: Qt.rgba(1.0, 1.0, 1.0, 0.45)
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 8

            // Indicator 1: Progress pill
            Rectangle {
                implicitWidth: progressContent.implicitWidth + 18
                implicitHeight: 24
                radius: 12
                color: Qt.rgba(1.0, 1.0, 1.0, 0.08)
                border.color: Theme.glassBorderSpecularLower
                border.width: 1

                RowLayout {
                    id: progressContent
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        objectName: "statusProgressText"
                        id: progressText
                        text: root.totalCount === 0
                              ? "Chưa mở dự án"
                              : root.compactMode
                                ? ("✓ " + root.acceptedCount + " / " + root.totalCount + " · " + root.progressPercent + "%")
                                : ("✓ " + root.acceptedCount + " / " + root.totalCount + " Đã duyệt · " + root.progressPercent + "%")
                        color: root.totalCount > 0 && root.acceptedCount === root.totalCount ? Theme.success : root.totalCount === 0 ? Theme.textMuted : Theme.textPrimaryGlass
                        font.pixelSize: 11
                        font.bold: true
                        ToolTip.visible: progressMouse.containsMouse
                        ToolTip.text: root.totalCount === 0 ? "Chưa mở tệp dự án nào" : root.acceptedCount + " / " + root.totalCount + " câu phụ đề đã được duyệt."
                        MouseArea { id: progressMouse; anchors.fill: parent; hoverEnabled: true }
                    }

                    Rectangle {
                        visible: !root.compactMode && root.totalCount > 0
                        Layout.preferredWidth: 60
                        Layout.preferredHeight: 4
                        Layout.alignment: Qt.AlignVCenter
                        color: Qt.rgba(255, 255, 255, 0.15)
                        radius: 2
                        clip: true
                        Rectangle {
                            width: parent.width * root.progressRatio
                            height: parent.height
                            color: Theme.success
                            radius: 2
                            Behavior on width { NumberAnimation { duration: Theme.animProgress; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Indicator 2: Engine Status pill
            Rectangle {
                implicitWidth: engineContent.implicitWidth + 20
                implicitHeight: 24
                radius: 12
                color: Qt.rgba(1.0, 1.0, 1.0, 0.08)
                border.color: Theme.glassBorderSpecularLower
                border.width: 1

                RowLayout {
                    id: engineContent
                    anchors.centerIn: parent
                    spacing: 6

                    Rectangle {
                        id: engineDot
                        width: 8; height: 8; radius: 4
                        Layout.alignment: Qt.AlignVCenter
                        visible: root.engineStatus !== "Translating" && root.engineStatus !== "Loading"
                        color: root.engineStatus === "Ready" ? Theme.success : root.engineStatus === "Error" ? Theme.danger : Theme.textMuted
                        Behavior on color { ColorAnimation { duration: Theme.animState; easing.type: Easing.OutQuad } }
                    }

                    AIActivityIndicator {
                        active: root.engineStatus === "Translating" || root.engineStatus === "Loading"
                        color: Theme.accentCyan
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        objectName: "engineStatusText"
                        id: engineText
                        text: root.compactMode ? root.engineStatus : "AI Engine: " + root.engineStatus
                        color: root.engineStatus === "Error" ? Theme.danger : Theme.textPrimaryGlass
                        font.pixelSize: 11
                        font.bold: true
                        ToolTip.visible: engineMouse.containsMouse
                        ToolTip.text: "Current status of the AI inference engine."
                        MouseArea { id: engineMouse; anchors.fill: parent; hoverEnabled: true }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Indicator 3: VRAM pill
            Rectangle {
                implicitWidth: vramContent.implicitWidth + 20
                implicitHeight: 24
                radius: 12
                color: Qt.rgba(1.0, 1.0, 1.0, 0.08)
                border.color: Theme.glassBorderSpecularLower
                border.width: 1

                RowLayout {
                    id: vramContent
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "⚡"
                        font.pixelSize: 10
                        color: Theme.accentSapphire
                    }

                    Text {
                        objectName: "vramStatusText"
                        id: vramText
                        text: root.vramTotal > 0 && root.vramUsed >= 0
                              ? ("VRAM " + root.vramUsed.toFixed(1) + " / " + root.vramTotal.toFixed(1) + (root.compactMode ? "" : " GB"))
                              : "VRAM —"
                        color: Theme.textSecondary
                        font.pixelSize: 11
                        font.bold: true
                        ToolTip.visible: vramMouse.containsMouse
                        ToolTip.text: root.vramTotal > 0 && root.vramUsed >= 0 ? "Used: " + root.vramUsed.toFixed(1) + " GB\nTotal: " + root.vramTotal.toFixed(1) + " GB" : "VRAM statistics unavailable"
                        MouseArea { id: vramMouse; anchors.fill: parent; hoverEnabled: true }
                    }
                }
            }
        }
    }
}
