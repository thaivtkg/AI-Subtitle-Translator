import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Dialog {
    id: root

    property var controller: typeof modelController !== "undefined" ? modelController : null

    title: ""
    modal: true
    dim: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    anchors.centerIn: Overlay.overlay

    width: Math.min(780, Overlay.overlay ? Overlay.overlay.width - 40 : 780)
    height: Math.min(640, Overlay.overlay ? Overlay.overlay.height - 40 : 640)
    padding: 0

    background: Rectangle {
        color: Theme.bgSurface
        radius: Theme.radius * 2
        border.color: Theme.border
        border.width: 1
    }

    Connections {
        target: root.controller
        function onDownloadProgress(modelId, percent, speed, eta) {
            // Danh sách tự cập nhật qua modelListChanged signal từ controller
        }
    }

    contentItem: ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ==========================================
        // HEADER DIALOG
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 52
            color: Theme.bgSurfaceElevated
            radius: Theme.radius * 2

            // Bo góc chỉ ở trên
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: Theme.radius * 2
                color: Theme.bgSurfaceElevated
            }
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Theme.border
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spaceLarge
                anchors.rightMargin: Theme.spaceMedium
                spacing: Theme.spaceSmall

                Text {
                    text: "◈ Quản Lý Mô Hình Dịch Thuật AI (LLM)"
                    color: Theme.textPrimary
                    font.pixelSize: 16
                    font.bold: true
                    Layout.fillWidth: true
                }

                AppButton {
                    text: "✕ Đóng"
                    onClicked: root.close()
                }
            }
        }

        // ==========================================
        // HARDWARE BANNER
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: hwLayout.implicitHeight + Theme.spaceMedium
            color: Theme.bgSurfaceSoft
            border.color: Theme.border
            border.width: 1

            RowLayout {
                id: hwLayout
                anchors.fill: parent
                anchors.leftMargin: Theme.spaceLarge
                anchors.rightMargin: Theme.spaceLarge
                spacing: Theme.spaceLarge

                RowLayout {
                    spacing: Theme.spaceSmall
                    Text { text: "🖥️ GPU:"; color: Theme.textMuted; font.pixelSize: 12; font.bold: true }
                    Text {
                        text: root.controller && root.controller.hardwareSummary ? root.controller.hardwareSummary.gpu_name : "N/A"
                        color: Theme.textPrimary
                        font.pixelSize: 12
                        font.bold: true
                    }
                }

                RowLayout {
                    spacing: Theme.spaceSmall
                    Text { text: "⚡ VRAM:"; color: Theme.textMuted; font.pixelSize: 12; font.bold: true }
                    Text {
                        text: root.controller && root.controller.hardwareSummary ? (root.controller.hardwareSummary.vram_gb.toFixed(1) + " GB") : "0 GB"
                        color: Theme.accentCyan
                        font.pixelSize: 12
                        font.bold: true
                    }
                }

                RowLayout {
                    spacing: Theme.spaceSmall
                    Text { text: "⚙️ Backend:"; color: Theme.textMuted; font.pixelSize: 12; font.bold: true }
                    Text {
                        text: root.controller && root.controller.hardwareSummary ? root.controller.hardwareSummary.backend_status : "CPU"
                        color: root.controller && root.controller.hardwareSummary && root.controller.hardwareSummary.has_cuda ? Theme.success : Theme.warning
                        font.pixelSize: 12
                        font.bold: true
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }

        // ==========================================
        // MODEL LIST
        // ==========================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ScrollView {
                anchors.fill: parent
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ListView {
                    id: modelListView
                    width: parent.width
                    spacing: Theme.spaceMedium
                    topMargin: Theme.spaceMedium
                    bottomMargin: Theme.spaceMedium
                    leftMargin: Theme.spaceLarge
                    rightMargin: Theme.spaceLarge

                    model: root.controller ? root.controller.models : []

                    delegate: ModelCard {
                        width: modelListView.width - (modelListView.leftMargin + modelListView.rightMargin)
                        modelData: modelData
                        controller: root.controller

                        onDownloadClicked: function(modelId) {
                            if (root.controller) root.controller.startDownload(modelId)
                        }

                        onCancelClicked: function(modelId) {
                            if (root.controller) root.controller.cancelDownload(modelId)
                        }

                        onUseClicked: function(modelId) {
                            if (root.controller) root.controller.selectActiveModel(modelId)
                        }

                        onSelectClicked: function(modelId) {
                            if (root.controller) root.controller.selectActiveModel(modelId)
                        }

                        onDeleteClicked: function(modelId) {
                            if (root.controller) root.controller.deleteModelFile(modelId)
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: !root.controller || !root.controller.models || root.controller.models.length === 0
                text: "Không có mô hình nào trong danh mục."
                color: Theme.textMuted
                font.pixelSize: 14
            }
        }
    }
}
