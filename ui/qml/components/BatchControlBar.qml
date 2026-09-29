import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Rectangle {
    id: root
    objectName: "batchControlBar"
    implicitHeight: 48
    color: Theme.bgSurface
    border.color: Theme.border
    border.width: 1

    property var controller: batchController
    property string sourceLanguage: "English"
    property string targetLanguage: "Vietnamese"
    property string storySummary: ""

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spaceMedium
        anchors.rightMargin: Theme.spaceMedium
        spacing: Theme.spaceSmall

        Text {
            objectName: "batchStatusText"
            text: {
                if (root.controller.cancelPending) return "Cancelling…"
                if (root.controller.state === "PAUSING") return "Pausing…"
                if (root.controller.state === "PAUSED") return "Paused"
                if (root.controller.state === "RUNNING") return "Batch running"
                if (root.controller.state === "CANCELLED") return "Cancelled"
                if (root.controller.state === "FAILED") return "Failed"
                if (root.controller.state === "COMPLETED") {
                    return root.controller.failedCount > 0 ? "Completed with failures" : "Complete"
                }
                return "Batch"
            }
            color: Theme.textSecondary
            font.pixelSize: 12
            font.bold: true
        }

        Text {
            objectName: "batchProgressText"
            text: root.controller.totalCount > 0
                  ? root.controller.progressPercent + "% · "
                    + root.controller.completedCount + "/"
                    + root.controller.totalCount
                    + (root.controller.failedCount > 0 ? " · " + root.controller.failedCount + " failed" : "")
                  : ""
            color: Theme.textMuted
            font.pixelSize: 12
        }

        Item { Layout.fillWidth: true }

        AppButton {
            objectName: "btnBatchStart"
            text: "Start Batch"
            visible: ["IDLE", "COMPLETED", "CANCELLED", "FAILED"].indexOf(root.controller.state) >= 0
            enabled: root.controller.canStart
            onClicked: root.controller.startBatch(root.sourceLanguage, root.targetLanguage, root.storySummary)
        }

        AppButton {
            objectName: "btnBatchPause"
            text: "Pause"
            visible: root.controller.state === "RUNNING" && !root.controller.cancelPending
            enabled: root.controller.canPause
            onClicked: root.controller.pauseBatch()
        }

        AppButton {
            objectName: "btnBatchResume"
            text: "Resume"
            visible: root.controller.state === "PAUSED"
            enabled: root.controller.canResume
            onClicked: root.controller.resumeBatch()
        }

        AppButton {
            objectName: "btnBatchCancel"
            text: root.controller.cancelPending ? "Cancelling…" : "Cancel"
            visible: root.controller.state === "RUNNING"
            enabled: root.controller.canCancel
            onClicked: root.controller.cancelBatch()
        }

        AppButton {
            objectName: "btnBatchRetryFailed"
            text: "Retry Failed"
            visible: root.controller.canRetryFailed
            enabled: root.controller.canRetryFailed
            onClicked: root.controller.retryFailed()
        }
    }
}
