import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Rectangle {
    id: root

    property var cardData: null
    property var controller: null

    // Thuộc tính nhận trực tiếp từ delegate hoặc fallback từ cardData
    property string modelId: ""
    property string displayName: ""
    property string sizeText: ""
    property string description: ""
    property string recommendationBadge: ""
    property string recommendationReason: ""
    property string status: "NOT_DOWNLOADED"
    property int downloadPercent: 0
    property string downloadSpeed: ""
    property string downloadEta: ""

    // Computed properties với fallback 2 chiều (bracket notation & dot notation)
    readonly property string effectiveModelId: modelId !== "" ? modelId : (cardData ? (cardData["model_id"] || cardData.model_id || "") : "")
    readonly property string effectiveDisplayName: displayName !== "" ? displayName : (cardData ? (cardData["display_name"] || cardData.display_name || "") : "")
    readonly property string effectiveSizeText: sizeText !== "" ? sizeText : (cardData ? (cardData["size_gb_formatted"] || cardData["size_formatted"] || cardData.size_gb_formatted || cardData.size_formatted || "") : "")
    readonly property string effectiveDescription: description !== "" ? description : (cardData ? (cardData["description"] || cardData.description || "") : "")
    readonly property string effectiveBadge: recommendationBadge !== "" ? recommendationBadge : (cardData ? (cardData["recommendation"] || cardData["badge"] || cardData.recommendation || cardData.badge || "") : "")
    readonly property string effectiveReason: recommendationReason !== "" ? recommendationReason : (cardData ? (cardData["recommendation_reason"] || cardData["reason"] || cardData.recommendation_reason || cardData.reason || "") : "")
    readonly property string effectiveStatus: status !== "NOT_DOWNLOADED" ? status : (cardData ? (cardData["status"] || cardData.status || "NOT_DOWNLOADED") : "NOT_DOWNLOADED")
    readonly property int effectiveDownloadPercent: downloadPercent > 0 ? downloadPercent : (cardData ? (cardData["download_percent"] !== undefined ? cardData["download_percent"] : (cardData["progress_percent"] || cardData.download_percent || cardData.progress_percent || 0)) : 0)
    readonly property string effectiveDownloadSpeed: downloadSpeed !== "" ? downloadSpeed : (cardData ? (cardData["download_speed"] || cardData["speed"] || cardData.download_speed || cardData.speed || "") : "")
    readonly property string effectiveDownloadEta: downloadEta !== "" ? downloadEta : (cardData ? (cardData["download_eta"] || cardData["eta"] || cardData.download_eta || cardData.eta || "") : "")

    readonly property bool isDownloaded: effectiveStatus === "DOWNLOADED" || effectiveStatus === "ACTIVE" || (cardData && (cardData["is_downloaded"] || cardData.is_downloaded))
    readonly property bool isDownloading: effectiveStatus === "DOWNLOADING" || (cardData && (cardData["is_downloading"] || cardData.is_downloading))
    readonly property bool isActive: effectiveStatus === "ACTIVE" || (cardData && (cardData["is_active"] || cardData.is_active))
    readonly property bool canDownload: (effectiveStatus === "NOT_DOWNLOADED" || (!isDownloaded && !isDownloading)) && (cardData ? (cardData["can_download"] !== undefined ? cardData["can_download"] : cardData.can_download) : true)
    readonly property bool canSelect: isDownloaded && !isActive && (cardData ? (cardData["can_select"] !== undefined ? cardData["can_select"] : cardData.can_select) : true)
    readonly property bool canDelete: isDownloaded && !isActive && (cardData ? (cardData["can_delete"] !== undefined ? cardData["can_delete"] : cardData.can_delete) : true)

    signal downloadClicked(string modelId)
    signal cancelClicked(string modelId)
    signal useClicked(string modelId)
    signal selectClicked(string modelId)
    signal deleteClicked(string modelId)

    implicitHeight: mainLayout.implicitHeight + Theme.spaceLarge
    color: root.isActive ? Theme.bgSurfaceSoft : Theme.bgSurfaceElevated
    radius: Theme.radius
    border.color: root.isActive ? Theme.accentCyan : (root.effectiveBadge === "RECOMMENDED" ? Theme.border : Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.5))
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
                text: root.effectiveDisplayName
                color: Theme.textPrimary
                font.pixelSize: 15
                font.bold: true
            }

            Text {
                text: root.effectiveSizeText
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
                visible: root.effectiveBadge !== ""
                color: {
                    if (root.effectiveBadge === "RECOMMENDED") return Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.15)
                    if (root.effectiveBadge === "COMPATIBLE") return Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.15)
                    return Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.15)
                }
                border.color: {
                    if (root.effectiveBadge === "RECOMMENDED") return Theme.success
                    if (root.effectiveBadge === "COMPATIBLE") return Theme.accentCyan
                    return Theme.warning
                }
                border.width: 1

                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: {
                        if (root.effectiveBadge === "RECOMMENDED") return "★ KHUYÊN DÙNG"
                        if (root.effectiveBadge === "COMPATIBLE") return "✓ TƯƠNG THÍCH"
                        return "⚠ CHƯA TỐI ƯU"
                    }
                    color: {
                        if (root.effectiveBadge === "RECOMMENDED") return Theme.success
                        if (root.effectiveBadge === "COMPATIBLE") return Theme.accentCyan
                        return Theme.warning
                    }
                    font.pixelSize: 11
                    font.bold: true
                }

                ToolTip.visible: badgeMouse.containsMouse
                ToolTip.text: root.effectiveReason
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
                isPrimary: root.effectiveBadge === "RECOMMENDED"
                visible: root.canDownload
                onClicked: root.downloadClicked(root.effectiveModelId)
            }

            // Nút: Hủy tải
            AppButton {
                text: "Hủy tải"
                visible: root.isDownloading
                onClicked: root.cancelClicked(root.effectiveModelId)
            }

            // Nút: Chọn sử dụng
            AppButton {
                text: "Sử dụng"
                isPrimary: true
                visible: root.canSelect
                onClicked: {
                    root.useClicked(root.effectiveModelId)
                    root.selectClicked(root.effectiveModelId)
                }
            }

            // Nút: Xóa file
            AppButton {
                text: "Xóa"
                visible: root.canDelete
                onClicked: root.deleteClicked(root.effectiveModelId)
            }
        }

        // Hàng 2: Mô tả chi tiết
        Text {
            Layout.fillWidth: true
            text: root.effectiveDescription
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
                    text: "Đang tải: " + root.effectiveDownloadPercent + "%"
                    color: Theme.accentCyan
                    font.pixelSize: 12
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.effectiveDownloadSpeed + (root.effectiveDownloadEta !== "" ? (" · ETA: " + root.effectiveDownloadEta) : "")
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
                    width: Math.max(0, Math.min(parent.width, parent.width * (root.effectiveDownloadPercent / 100.0)))
                    height: parent.height
                    color: Theme.accentCyan
                    radius: 3
                }
            }
        }
    }
}
