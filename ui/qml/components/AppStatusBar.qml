import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Rectangle {
    id: root
    implicitHeight: 32
    color: Theme.bgApp

    Rectangle { width: parent.width; height: 1; color: Theme.border; anchors.top: parent.top }

    property int acceptedCount: 0
    property int totalCount: 0
    property string engineStatus: "Not loaded"
    property real vramUsed: -1.0
    property real vramTotal: -1.0
    readonly property bool compactMode: width < 1150

    property real progressRatio: totalCount > 0 ? acceptedCount / totalCount : 0
    property int progressPercent: Math.round(progressRatio * 100)

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.compactMode ? Theme.spaceSmall : Theme.spaceMedium
        anchors.rightMargin: root.compactMode ? Theme.spaceSmall : Theme.spaceMedium
        spacing: 0

        RowLayout {
            spacing: Theme.spaceSmall
            Layout.alignment: Qt.AlignVCenter
            Text {
                objectName: "statusProgressText"
                id: progressText
                text: root.totalCount === 0
                      ? "No project"
                      : root.compactMode
                        ? ("✓ " + root.acceptedCount + " / " + root.totalCount + " · " + root.progressPercent + "%")
                        : ("✓ " + root.acceptedCount + " / " + root.totalCount + " Accepted · " + root.progressPercent + "%")
                color: root.totalCount > 0 && root.acceptedCount === root.totalCount ? Theme.success : root.totalCount === 0 ? Theme.textMuted : Theme.textSecondary
                font.pixelSize: 12
                ToolTip.visible: progressMouse.containsMouse
                ToolTip.text: root.totalCount === 0 ? "No project loaded" : root.acceptedCount + " of " + root.totalCount + " subtitles accepted."
                MouseArea { id: progressMouse; anchors.fill: parent; hoverEnabled: true }
            }
            Rectangle {
                visible: !root.compactMode && root.totalCount > 0
                Layout.preferredWidth: 80
                Layout.preferredHeight: 3
                Layout.alignment: Qt.AlignVCenter
                color: Theme.bgSurfaceElevated
                radius: 1
                clip: true
                Rectangle {
                    width: parent.width * root.progressRatio
                    height: parent.height
                    color: Theme.success
                    radius: 1
                    Behavior on width { NumberAnimation { duration: Theme.animProgress; easing.type: Easing.OutCubic } }
                }
            }
        }

        Item { Layout.fillWidth: true }

        RowLayout {
            spacing: root.compactMode ? Theme.spaceSmall : Theme.spaceMedium
            Layout.alignment: Qt.AlignVCenter
            Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 14; color: Theme.border }
            RowLayout {
                spacing: Theme.spaceSmall
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
                    color: root.engineStatus === "Error" ? Theme.danger : Theme.textSecondary
                    font.pixelSize: 12
                    ToolTip.visible: engineMouse.containsMouse
                    ToolTip.text: "Current status of the AI inference engine."
                    MouseArea { id: engineMouse; anchors.fill: parent; hoverEnabled: true }
                }
            }
            Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 14; color: Theme.border }
        }

        Item { Layout.fillWidth: true }

        RowLayout {
            spacing: Theme.spaceSmall
            Layout.alignment: Qt.AlignVCenter
            Text {
                objectName: "vramStatusText"
                id: vramText
                text: root.vramTotal > 0 && root.vramUsed >= 0
                      ? ("VRAM " + root.vramUsed.toFixed(1) + " / " + root.vramTotal.toFixed(1) + (root.compactMode ? "" : " GB"))
                      : "VRAM —"
                color: Theme.textSecondary
                font.pixelSize: 12
                ToolTip.visible: vramMouse.containsMouse
                ToolTip.text: root.vramTotal > 0 && root.vramUsed >= 0 ? "Used: " + root.vramUsed.toFixed(1) + " GB\nTotal: " + root.vramTotal.toFixed(1) + " GB" : "VRAM statistics unavailable"
                MouseArea { id: vramMouse; anchors.fill: parent; hoverEnabled: true }
            }
        }
    }
}
