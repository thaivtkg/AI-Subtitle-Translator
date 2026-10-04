import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Rectangle {
    id: root

    property var modelData: null
    property var controller: null

    signal downloadClicked(string modelId)
    signal cancelClicked(string modelId)
    signal selectClicked(string modelId)
    signal deleteClicked(string modelId)

    implicitHeight: mainLayout.implicitHeight + Theme.spaceLarge
    color: modelData && modelData.is_active ? Theme.bgSurfaceSoft : Theme.bgSurfaceElevated
    radius: Theme.radius
    border.color: modelData && modelData.is_active ? Theme.accentCyan : (modelData && modelData.badge === "RECOMMENDED" ? Theme.border : Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.5))
    border.width: modelData && modelData.is_active ? 2 : 1

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: Theme.spaceMedium
        spacing: Theme.spaceSmall

        // Hàng 1: Tiêu đề, Badge khuyên dùng, Kích thước file
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceSmall

            Text {
                text: root.modelData ? root.modelData.display_name : ""
                color: Theme.textPrimary
                font.pixelSize: 15
                font.bold: true
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            // Recommendation Badge
            Rectangle {
                id: badgeRect
                implicitWidth: badgeText.implicitWidth + Theme.spaceMedium
                implicitHeight: 22
                radius: 11
                visible: root.modelData && root.modelData.badge !== ""
                color: {
                    if (!root.modelData) return Theme.bgSurfaceSoft
                    if (root.modelData.badge === "RECOMMENDED") return Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.15)
                    if (root.modelData.badge === "COMPATIBLE") return Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.15)
                    return Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.15)
                }
                border.color: {
                    if (!root.modelData) return Theme.border
                    if (root.modelData.badge === "RECOMMENDED") return Theme.success
                    if (root.modelData.badge === "COMPATIBLE") return Theme.accentCyan
                    return Theme.warning
                }
                border.width: 1

                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: {
                        if (!root.modelData) return ""
                        if (root.modelData.badge === "RECOMMENDED") return "★ KHUYÊN DÙNG"
                        if (root.modelData.badge === "COMPATIBLE") return "✓ TƯƠNG THÍCH"
                        return "⚠ CHƯA TỐI ƯU"
                    }
                    color: {
                        if (!root.modelData) return Theme.textMuted
                        if (root.modelData.badge === "RECOMMENDED") return Theme.success
                        if (root.modelData.badge === "COMPATIBLE") return Theme.accentCyan
                        return Theme.warning
                    }
                    font.pixelSize: 11
                    font.bold: true
                }

                ToolTip.visible: badgeMouse.containsMouse
                ToolTip.text: root.modelData ? root.modelData.reason : ""
                MouseArea {
                    id: badgeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }

            // Kích thước dung lượng
            Text {
                text: root.modelData ? root.modelData.size_formatted : ""
                color: Theme.textMuted
                font.pixelSize: 13
                font.bold: true
            }
        }

        // Hàng 2: Mô tả chi tiết
        Text {
            Layout.fillWidth: true
            text: root.modelData ? root.modelData.description : ""
            color: Theme.textSecondary
            font.pixelSize: 13
            wrapMode: Text.WordWrap
            lineHeight: 1.2
        }

        // Hàng 3: Tiến trình tải nếu đang downloading
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.modelData && root.modelData.is_downloading
            spacing: Theme.spaceXs

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: root.modelData ? ("Đang tải: " + root.modelData.progress_percent + "%") : ""
                    color: Theme.accentCyan
                    font.pixelSize: 12
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.modelData ? (root.modelData.speed + " · ETA: " + root.modelData.eta) : ""
                    color: Theme.textMuted
                    font.pixelSize: 12
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 6
                color: Theme.bgSurfaceSoft
                radius: 3
                clip: true

                Rectangle {
                    width: parent.width * (root.modelData ? (root.modelData.progress_percent / 100.0) : 0)
                    height: parent.height
                    color: Theme.accentCyan
                    radius: 3
                }
            }
        }

        // Hàng 4: Trạng thái và Nút bấm thao tác
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Theme.spaceXs
            spacing: Theme.spaceSmall

            // Tag trạng thái: Active hoặc Downloaded
            Rectangle {
                implicitWidth: statusLabel.implicitWidth + Theme.spaceMedium
                implicitHeight: 24
                radius: 4
                visible: root.modelData && (root.modelData.is_active || root.modelData.is_downloaded) && !root.modelData.is_downloading
                color: root.modelData && root.modelData.is_active ? Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.2) : Theme.bgSurfaceSoft
                border.color: root.modelData && root.modelData.is_active ? Theme.accentCyan : Theme.border
                border.width: 1

                Text {
                    id: statusLabel
                    anchors.centerIn: parent
                    text: root.modelData && root.modelData.is_active ? "⚡ ĐANG SỬ DỤNG" : "✓ ĐÃ TẢI VỀ"
                    color: root.modelData && root.modelData.is_active ? Theme.accentCyan : Theme.textSecondary
                    font.pixelSize: 11
                    font.bold: true
                }
            }

            Item { Layout.fillWidth: true }

            // Nút: Tải về
            AppButton {
                text: "Tải model"
                visible: root.modelData && root.modelData.can_download
                onClicked: if (root.modelData) root.downloadClicked(root.modelData.model_id)
            }

            // Nút: Hủy tải
            AppButton {
                text: "Hủy tải"
                visible: root.modelData && root.modelData.is_downloading
                onClicked: if (root.modelData) root.cancelClicked(root.modelData.model_id)
            }

            // Nút: Chọn sử dụng
            AppButton {
                text: "Sử dụng"
                visible: root.modelData && root.modelData.can_select
                onClicked: if (root.modelData) root.selectClicked(root.modelData.model_id)
            }

            // Nút: Xóa file
            AppButton {
                text: "Xóa"
                visible: root.modelData && root.modelData.can_delete
                onClicked: if (root.modelData) root.deleteClicked(root.modelData.model_id)
            }
        }
    }
}
