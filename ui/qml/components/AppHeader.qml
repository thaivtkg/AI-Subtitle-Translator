import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import "../theme"

ToolBar {
    id: root
    property string projectName: "Untitled"
    property bool isSaved: true
    property bool hasProject: false
    property bool hasProjectData: false
    property bool projectMutationLocked: false
    property string sourceLanguage: "English"
    property string targetLanguage: "Vietnamese"
    property string storySummary: ""
    property int currentSubtitleIndex: 0
    property var selectedIndices: []
    readonly property bool isCompact: width < 1280
    readonly property bool isMinimum: width < 1100

    signal openSrtClicked()
    signal openProjectClicked()
    signal saveClicked()
    signal exportClicked()
    signal modelManagerClicked()

    implicitHeight: 48
    padding: 0

    background: Rectangle {
        color: Theme.bgApp
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: Theme.border
        }
    }

    contentItem: Item {
        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.LeftButton
            onPressed: Window.window.startSystemMove()
        }

        // CỤM ĐIỀU KHIỂN CỬA SỔ (LUÔN GHIM GÓC PHẢI TRÊN, KHÔNG BAO GIỜ BỊ ĐẨY MẤT)
        RowLayout {
            id: windowControlsRow
            objectName: "windowControlsRow"
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            spacing: 0
            z: 2

            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Theme.border }

            Button {
                objectName: "btnMinimize"
                implicitWidth: 46; implicitHeight: 48
                ToolTip.visible: hovered
                ToolTip.text: "Minimize"
                contentItem: Text { text: "—"; color: Theme.textSecondary; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.bold: true }
                background: Rectangle { color: parent.hovered ? Theme.bgSurfaceSoft : "transparent" }
                onClicked: Window.window.showMinimized()
            }
            Button {
                objectName: "btnMaximize"
                implicitWidth: 46; implicitHeight: 48
                ToolTip.visible: hovered
                ToolTip.text: Window.window.visibility === Window.Maximized ? "Restore" : "Maximize"
                contentItem: Text { text: Window.window.visibility === Window.Maximized ? "🗗" : "🗖"; color: Theme.textSecondary; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                background: Rectangle { color: parent.hovered ? Theme.bgSurfaceSoft : "transparent" }
                onClicked: {
                    if (Window.window.visibility === Window.Maximized) Window.window.showNormal()
                    else Window.window.showMaximized()
                }
            }
            Button {
                objectName: "btnClose"
                implicitWidth: 46; implicitHeight: 48
                ToolTip.visible: hovered
                ToolTip.text: "Close"
                contentItem: Text { text: "✕"; color: parent.hovered ? "#FFFFFF" : Theme.textSecondary; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                background: Rectangle { color: parent.hovered ? Theme.danger : "transparent" }
                onClicked: Window.window.close()
            }
        }

        // CỤM PHẢI: CÁC THAO TÁC CHÍNH (GHIM TRỰC TIẾP VÀO MÉP TRÁI CỤM ĐIỀU KHIỂN CỬA SỔ, ĐẢM BẢO KHÔNG BAO GIỜ BỊ ĐÈ)
        RowLayout {
            id: rightActionsRow
            objectName: "rightActionsRow"
            anchors.right: windowControlsRow.left
            anchors.rightMargin: root.isCompact ? Theme.spaceSmall : Theme.spaceMedium
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.isCompact ? Theme.spaceXs : Theme.spaceSmall
            z: 1

            // Nhóm nạp file
            AppButton {
                objectName: "btnOpenSrt"
                text: root.isCompact ? "SRT" : "Mở SRT"
                tooltip: "Mở file SRT — Ctrl + O"
                enabled: !root.projectMutationLocked
                onClicked: root.openSrtClicked()
            }
            AppButton {
                objectName: "btnOpenProject"
                text: root.isCompact ? "Dự án" : "Mở dự án"
                tooltip: "Mở file dự án — Ctrl + Shift + O"
                enabled: !root.projectMutationLocked
                onClicked: root.openProjectClicked()
            }

            Rectangle {
                visible: root.hasProject
                Layout.preferredWidth: 1
                Layout.preferredHeight: 16
                color: Theme.border
                Layout.margins: Theme.spaceXs
            }

            // Nhóm Primary Action: Dịch tự động
            HeaderBatchControl {
                id: headerBatch
                visible: root.hasProject
                sourceLanguage: root.sourceLanguage
                targetLanguage: root.targetLanguage
                storySummary: root.storySummary
                isCompact: root.isCompact
                currentSubtitleIndex: root.currentSubtitleIndex
                selectedIndices: root.selectedIndices
            }

            Rectangle {
                visible: root.hasProject
                Layout.preferredWidth: 1
                Layout.preferredHeight: 16
                color: Theme.border
                Layout.margins: Theme.spaceXs
            }

            // Nhóm xuất bản: Lưu & Xuất SRT
            AppButton {
                objectName: "btnSave"
                visible: root.hasProject
                text: "Lưu"
                tooltip: "Lưu dự án — Ctrl + S"
                enabled: root.hasProject && !root.isSaved
                onClicked: root.saveClicked()
            }
            AppButton {
                objectName: "btnExport"
                visible: root.hasProject
                text: root.isCompact ? "Xuất" : "Xuất SRT"
                tooltip: "Xuất file phụ đề SRT — Ctrl + Shift + S"
                isPrimary: true
                enabled: root.hasProject && root.hasProjectData
                onClicked: root.exportClicked()
            }
        }

        // CỤM TRÁI: LOGO STUDIO + TÊN DỰ ÁN (GHIM VÀO MÉP TRÁI CỬA SỔ)
        RowLayout {
            id: leftBrandingRow
            objectName: "leftBrandingRow"
            anchors.left: parent.left
            anchors.leftMargin: Theme.spaceMedium
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spaceSmall

            Text {
                text: root.isCompact ? "◈ Studio" : "◈ AI Subtitle Studio"
                color: Theme.accentCyan
                font.pixelSize: 14
                font.bold: true
            }

            Rectangle {
                implicitWidth: 32
                implicitHeight: 18
                radius: 4
                color: Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.12)
                border.color: Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.3)
                border.width: 1
                Layout.alignment: Qt.AlignVCenter
                Text {
                    anchors.centerIn: parent
                    text: "v1.2"
                    color: Theme.accentCyan
                    font.pixelSize: 10
                    font.bold: true
                }
            }

            Rectangle {
                visible: root.hasProject
                implicitWidth: 1
                implicitHeight: 14
                color: Theme.border
                Layout.leftMargin: Theme.spaceXs
                Layout.rightMargin: Theme.spaceXs
            }

            Text {
                visible: root.hasProject
                text: root.projectName
                color: Theme.textPrimary
                font.pixelSize: 14
                font.bold: true
                elide: Text.ElideRight
                Layout.maximumWidth: root.isCompact ? 120 : 200
            }

            Rectangle {
                visible: root.hasProject
                Layout.minimumWidth: 0
                Layout.preferredWidth: root.hasProject ? implicitWidth : 0
                implicitWidth: statusText.implicitWidth + (root.isCompact ? Theme.spaceSmall : Theme.spaceMedium)
                implicitHeight: 20
                radius: 10
                color: root.isSaved ? Theme.bgSurfaceElevated : Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.15)
                border.color: root.isSaved ? Theme.border : Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.3)
                border.width: 1

                Text {
                    id: statusText
                    anchors.centerIn: parent
                    text: root.isSaved ? (root.isCompact ? "✓" : "✓ Đã lưu") : (root.isCompact ? "●" : "● Chưa lưu")
                    color: root.isSaved ? Theme.textSecondary : Theme.warning
                    font.pixelSize: 11
                    font.bold: true
                }

                ToolTip.visible: chipMouse.containsMouse
                ToolTip.text: root.isSaved ? "Dự án đã được lưu" : "Có thay đổi chưa lưu"
                MouseArea {
                    id: chipMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }
            }
        }

        // CỤM GIỮA: CHIP CHỌN MÔ HÌNH AI TRUNG TÂM (CÂN ĐỐI TRONG KHOẢNG TRỐNG GIỮA TRÁI VÀ PHẢI)
        Item {
            id: centerCluster
            anchors.left: leftBrandingRow.right
            anchors.leftMargin: Theme.spaceSmall
            anchors.right: rightActionsRow.left
            anchors.rightMargin: Theme.spaceSmall
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            clip: true

            AppButton {
                objectName: "btnModelManager"
                anchors.centerIn: parent
                visible: parent.width >= 80
                text: {
                    if (typeof modelController === "undefined") return "⚡ Mô hình AI ▼"
                    if (parent.width < 220) return "⚡ Mô hình ▼"
                    return "⚡ " + modelController.activeModelDisplayName + " ▼"
                }
                tooltip: typeof modelController !== "undefined"
                         ? ("Mô hình đang dùng: " + modelController.activeModelDisplayName + " — Click để thay đổi")
                         : "Quản lý & Chọn Mô hình AI — Click để thay đổi"
                onClicked: root.modelManagerClicked()
            }
        }
    }
}
