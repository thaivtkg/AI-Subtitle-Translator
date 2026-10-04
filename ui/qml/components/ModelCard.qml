import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Rectangle {
    id: root

    property var modelData: null
    property var controller: null

    // Thuộc tính nhận từ ListView delegate hoặc fallback từ modelData
    property string modelId: modelData ? (modelData.model_id || "") : ""
    property string displayName: modelData ? (modelData.display_name || "") : ""
    property string sizeText: modelData ? (modelData.size_gb_formatted || modelData.size_formatted || "") : ""
    property string description: modelData ? (modelData.description || "") : ""
    property string recommendationBadge: modelData ? (modelData.recommendation || modelData.badge || "") : ""
    property string recommendationReason: modelData ? (modelData.recommendation_reason || modelData.reason || "") : ""
    property string status: modelData ? (modelData.status || "NOT_DOWNLOADED") : "NOT_DOWNLOADED"
    property int downloadPercent: modelData ? (modelData.download_percent !== undefined ? modelData.download_percent : (modelData.progress_percent || 0)) : 0
    property string downloadSpeed: modelData ? (modelData.download_speed || modelData.speed || "") : ""
    property string downloadEta: modelData ? (modelData.download_eta || modelData.eta || "") : ""

    readonly property bool isDownloaded: status === "DOWNLOADED" || status === "ACTIVE" || (modelData && modelData.is_downloaded)
    readonly property bool isDownloading: status === "DOWNLOADING" || (modelData && modelData.is_downloading)
    readonly property bool isActive: status === "ACTIVE" || (modelData && modelData.is_active)
    readonly property bool canDownload: (status === "NOT_DOWNLOADED" || (!isDownloaded && !isDownloading)) && (modelData ? modelData.can_download : true)
    readonly property bool canSelect: isDownloaded && !isActive && (modelData ? modelData.can_select : true)
    readonly property bool canDelete: isDownloaded && !isActive && (modelData ? modelData.can_delete : true)

    signal downloadClicked(string modelId)
    signal cancelClicked(string modelId)
    signal useClicked(string modelId)
    signal selectClicked(string modelId)
    signal deleteClicked(string modelId)

    implicitHeight: mainLayout.implicitHeight + Theme.spaceLarge
    color: root.isActive ? Theme.bgSurfaceSoft : Theme.bgSurfaceElevated
    radius: Theme.radius
    border.color: root.isActive ? Theme.accentCyan : (root.recommendationBadge === "RECOMMENDED" ? Theme.border : Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.5))
    border.width: root.isActive ? 2 : 1

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: Theme.spaceMedium
        spacing: Theme.spaceSmall

        // Hàng 1: Tiêu đề, Dung lượng, Badge khuyên dùng, Spacer, Nút bấm thao tác
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceSmall

            Text {
                text: root.displayName
                color: Theme.textPrimary
                font.pixelSize: 15
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                text: root.sizeText
                color: Theme.textMuted
                font.pixelSize: 13
                font.bold: true
            }

            // Recommendation Badge
            Rectangle {
                id: badgeRect
                implicitWidth: badgeText.implicitWidth + Theme.spaceMedium
                implicitHeight: 22
                radius: 11
                visible: root.recommendationBadge !== ""
                color: {
                    if (root.recommendationBadge === "RECOMMENDED") return Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.15)
                    if (root.recommendationBadge === "COMPATIBLE") return Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.15)
                    return Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.15)
                }
                border.color: {
                    if (root.recommendationBadge === "RECOMMENDED") return Theme.success
                    if (root.recommendationBadge === "COMPATIBLE") return Theme.accentCyan
                    return Theme.warning
                }
                border.width: 1

                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: {
                        if (root.recommendationBadge === "RECOMMENDED") return "★ KHUYÊN DÙNG"
                        if (root.recommendationBadge === "COMPATIBLE") return "✓ TƯƠNG THÍCH"
                        return "⚠ CHƯA TỐI ƯU"
                    }
                    color: {
                        if (root.recommendationBadge === "RECOMMENDED") return Theme.success
                        if (root.recommendationBadge === "COMPATIBLE") return Theme.accentCyan
                        return Theme.warning
                    }
                    font.pixelSize: 11
                    font.bold: true
                }

                ToolTip.visible: badgeMouse.containsMouse
                ToolTip.text: root.recommendationReason
                MouseArea {
                    id: badgeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }

            // Spacer đẩy các nút sang phải
            Item { Layout.fillWidth: true }

            // Tag trạng thái: Active hoặc Downloaded
            Rectangle {
                implicitWidth: statusLabel.implicitWidth + Theme.spaceMedium
                implicitHeight: 24
                radius: 4
                visible: (root.isActive || root.isDownloaded) && !root.isDownloading
                color: root.isActive ? Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.2) : Theme.bgSurfaceSoft
                border.color: root.isActive ? Theme.accentCyan : Theme.border
                border.width: 1

                Text {
                    id: statusLabel
                    anchors.centerIn: parent
                    text: root.isActive ? "⚡ ĐANG SỬ DỤNG" : "✓ ĐÃ TẢI VỀ"
                    color: root.isActive ? Theme.accentCyan : Theme.textSecondary
                    font.pixelSize: 11
                    font.bold: true
                }
            }

            // Nút: Tải về
            AppButton {
                text: "Tải model"
                isPrimary: root.recommendationBadge === "RECOMMENDED"
                visible: root.canDownload
                onClicked: root.downloadClicked(root.modelId)
            }

            // Nút: Hủy tải
            AppButton {
                text: "Hủy tải"
                visible: root.isDownloading
                onClicked: root.cancelClicked(root.modelId)
            }

            // Nút: Chọn sử dụng
            AppButton {
                text: "Sử dụng"
                isPrimary: true
                visible: root.canSelect
                onClicked: {
                    root.useClicked(root.modelId)
                    root.selectClicked(root.modelId)
                }
            }

            // Nút: Xóa file
            AppButton {
                text: "Xóa"
                visible: root.canDelete
                onClicked: root.deleteClicked(root.modelId)
            }
        }

        // Hàng 2: Mô tả chi tiết
        Text {
            Layout.fillWidth: true
            text: root.description
            color: Theme.textSecondary
            font.pixelSize: 13
            wrapMode: Text.WordWrap
            lineHeight: 1.2
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        // Hàng 3: Tiến trình tải nếu đang downloading
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.isDownloading
            spacing: Theme.spaceXs

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Đang tải: " + root.downloadPercent + "%"
                    color: Theme.accentCyan
                    font.pixelSize: 12
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.downloadSpeed + (root.downloadEta !== "" ? (" · ETA: " + root.downloadEta) : "")
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
                    width: Math.max(0, Math.min(parent.width, parent.width * (root.downloadPercent / 100.0)))
                    height: parent.height
                    color: Theme.accentCyan
                    radius: 3
                }
            }
        }
    }
}
