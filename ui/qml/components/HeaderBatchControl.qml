import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Item {
    id: root
    objectName: "batchControlBar"

    property var controller: batchController
    property string sourceLanguage: "English"
    property string targetLanguage: "Vietnamese"
    property string storySummary: ""
    property bool isCompact: false

    property int selectedLimit: 50
    property int currentSubtitleIndex: 0

    implicitWidth: contentRow.implicitWidth
    implicitHeight: 32

    RowLayout {
        id: contentRow
        anchors.fill: parent
        spacing: Theme.spaceSmall

        Text {
            objectName: "batchStatusText"
            visible: root.controller.state !== "IDLE"
            text: {
                if (root.controller.cancelPending) return "Đang hủy…"
                if (root.controller.state === "PAUSING") return "Đang tạm dừng…"
                if (root.controller.state === "PAUSED") return "Đã tạm dừng"
                if (root.controller.state === "RUNNING") return "Đang dịch lô…"
                if (root.controller.state === "CANCELLED") return "Đã hủy"
                if (root.controller.state === "FAILED") return "Thất bại"
                if (root.controller.state === "COMPLETED") {
                    return root.controller.failedCount > 0 ? "Hoàn tất có lỗi" : "Hoàn tất"
                }
                return ""
            }
            color: root.controller.state === "FAILED" || root.controller.failedCount > 0 ? Theme.danger :
                   root.controller.state === "PAUSED" ? Theme.warning : Theme.textSecondary
            font.pixelSize: 12
            font.bold: true
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            objectName: "batchProgressText"
            visible: root.controller.state !== "IDLE" && root.controller.totalCount > 0
            text: root.controller.totalCount > 0
                  ? root.controller.progressPercent + "% · "
                    + root.controller.completedCount + "/"
                    + root.controller.totalCount
                    + (root.controller.failedCount > 0 ? " · " + root.controller.failedCount + " lỗi" : "")
                  : ""
            color: Theme.textMuted
            font.pixelSize: 12
            Layout.alignment: Qt.AlignVCenter
        }

        AppButton {
            objectName: "btnBatchStart"
            text: root.selectedLimit === 0 ? "⚡ Dịch toàn bộ" : "⚡ Dịch " + root.selectedLimit + " câu"
            tooltip: "Dịch tự động phụ đề theo lô"
            isPrimary: true
            visible: ["IDLE", "COMPLETED", "CANCELLED", "FAILED"].indexOf(root.controller.state) >= 0
            enabled: root.controller.canStart
            onClicked: {
                root.controller.startBatch(
                    root.sourceLanguage,
                    root.targetLanguage,
                    root.storySummary,
                    root.currentSubtitleIndex >= 0 ? root.currentSubtitleIndex : 0,
                    root.selectedLimit
                )
            }
        }

        AppButton {
            objectName: "btnBatchPresetMenu"
            text: "▾"
            tooltip: "Chọn số lượng câu dịch mỗi lần"
            isPrimary: true
            Layout.preferredWidth: 26
            visible: ["IDLE", "COMPLETED", "CANCELLED", "FAILED"].indexOf(root.controller.state) >= 0
            enabled: root.controller.canStart
            onClicked: presetMenu.open()

            Menu {
                id: presetMenu
                y: parent.height + 4
                width: 190
                background: Rectangle {
                    color: Theme.bgSurfaceElevated
                    border.color: Theme.border
                    border.width: 1
                    radius: Theme.radius
                }

                MenuItem {
                    text: "⚡ 10 câu (Thử AI)"
                    contentItem: Text { text: parent.text; color: Theme.textPrimary; font.pixelSize: 12 }
                    onTriggered: root.selectedLimit = 10
                }
                MenuItem {
                    text: "⚡ 50 câu (Khuyên dùng)"
                    contentItem: Text { text: parent.text; color: Theme.textPrimary; font.pixelSize: 12 }
                    onTriggered: root.selectedLimit = 50
                }
                MenuItem {
                    text: "⚡ Toàn bộ tệp"
                    contentItem: Text { text: parent.text; color: Theme.textPrimary; font.pixelSize: 12 }
                    onTriggered: root.selectedLimit = 0
                }
            }
        }

        AppButton {
            objectName: "btnBatchPause"
            text: "Tạm dừng"
            tooltip: "Tạm dừng tiến trình dịch"
            visible: root.controller.state === "RUNNING" && !root.controller.cancelPending
            enabled: root.controller.canPause
            onClicked: root.controller.pauseBatch()
        }

        AppButton {
            objectName: "btnBatchResume"
            text: "Tiếp tục"
            tooltip: "Tiếp tục tiến trình dịch"
            visible: root.controller.state === "PAUSED"
            enabled: root.controller.canResume
            onClicked: root.controller.resumeBatch()
        }

        AppButton {
            objectName: "btnBatchCancel"
            text: root.controller.cancelPending ? "Đang hủy…" : "Hủy"
            tooltip: "Hủy tiến trình dịch"
            visible: root.controller.state === "RUNNING" || root.controller.cancelPending
            enabled: root.controller.canCancel
            onClicked: root.controller.cancelBatch()
        }

        AppButton {
            objectName: "btnBatchRetryFailed"
            text: "Thử lại lỗi"
            tooltip: "Dịch lại các câu bị lỗi"
            visible: root.controller.canRetryFailed
            enabled: root.controller.canRetryFailed
            onClicked: root.controller.retryFailed()
        }
    }
}
