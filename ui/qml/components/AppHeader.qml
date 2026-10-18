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

    implicitHeight: 52
    padding: 0

    background: Rectangle {
        color: "transparent"
    }

    contentItem: Item {
        // FLOATING LIQUID GLASS CAPSULE SHELL
        Rectangle {
            id: headerCapsule
            anchors.fill: parent
            anchors.leftMargin: Theme.windowPadding
            anchors.rightMargin: Theme.windowPadding
            anchors.topMargin: 4
            anchors.bottomMargin: 4
            radius: 22
            color: Theme.glassIslandSurface
            border.color: Theme.glassBorderSpecularUpper
            border.width: 1
            clip: true

            // Specular Gleam Highlight along the upper bevel
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Theme.glassGleamWhite
                radius: parent.radius
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                acceptedButtons: Qt.LeftButton
                onPressed: Window.window.startSystemMove()
            }

            // MACOS GLASS GEMS (WINDOW CONTROLS ANCHORED LEFT)
            RowLayout {
                id: windowControlsRow
                objectName: "windowControlsRow"
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                z: 3

                Button {
                    id: btnClose
                    objectName: "btnClose"
                    implicitWidth: 14
                    implicitHeight: 14
                    padding: 0
                    ToolTip.visible: hovered
                    ToolTip.text: "Đóng"
                    contentItem: Text {
                        text: "✕"
                        color: btnClose.hovered ? "#FFFFFF" : "transparent"
                        font.pixelSize: 8
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 7
                        color: btnClose.pressed ? "#CC2D24" : (btnClose.hovered ? "#FF453A" : "#FF5F56")
                        border.color: "#E0443E"
                        border.width: 1
                    }
                    onClicked: Window.window.close()
                }

                Button {
                    id: btnMinimize
                    objectName: "btnMinimize"
                    implicitWidth: 14
                    implicitHeight: 14
                    padding: 0
                    ToolTip.visible: hovered
                    ToolTip.text: "Thu nhỏ"
                    contentItem: Text {
                        text: "—"
                        color: btnMinimize.hovered ? "#5F3E00" : "transparent"
                        font.pixelSize: 8
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 7
                        color: btnMinimize.pressed ? "#CCA024" : (btnMinimize.hovered ? "#FF9F0A" : "#FFBD2E")
                        border.color: "#DEA123"
                        border.width: 1
                    }
                    onClicked: Window.window.showMinimized()
                }

                Button {
                    id: btnMaximize
                    objectName: "btnMaximize"
                    implicitWidth: 14
                    implicitHeight: 14
                    padding: 0
                    ToolTip.visible: hovered
                    ToolTip.text: Window.window.visibility === Window.Maximized ? "Khôi phục" : "Phóng to"
                    contentItem: Text {
                        text: "+"
                        color: btnMaximize.hovered ? "#0A4E1B" : "transparent"
                        font.pixelSize: 10
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 7
                        color: btnMaximize.pressed ? "#209E38" : (btnMaximize.hovered ? "#30D158" : "#27C93F")
                        border.color: "#1AAB29"
                        border.width: 1
                    }
                    onClicked: {
                        if (Window.window.visibility === Window.Maximized) Window.window.showNormal()
                        else Window.window.showMaximized()
                    }
                }
            }

            // CỤM TRÁI: LOGO STUDIO + TÊN DỰ ÁN
            RowLayout {
                id: leftBrandingRow
                objectName: "leftBrandingRow"
                anchors.left: windowControlsRow.right
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spaceSmall

                Text {
                    text: root.isCompact ? "◈ Studio" : "◈ AI Subtitle Studio"
                    color: Theme.textPrimaryGlass
                    font.pixelSize: 13
                    font.bold: true
                }

                Rectangle {
                    implicitWidth: verText.implicitWidth + 10
                    implicitHeight: 18
                    radius: 9
                    color: Qt.rgba(1, 1, 1, 0.22)
                    border.color: Theme.glassBorderSpecularUpper
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter
                    Text {
                        id: verText
                        anchors.centerIn: parent
                        text: "v1.2 Liquid"
                        color: Theme.textPrimaryGlass
                        font.pixelSize: 10
                        font.bold: true
                    }
                }

                Rectangle {
                    visible: root.hasProject
                    implicitWidth: 1
                    implicitHeight: 14
                    color: Theme.glassBorderSubtle
                    Layout.leftMargin: Theme.spaceXs
                    Layout.rightMargin: Theme.spaceXs
                }

                Text {
                    visible: root.hasProject
                    text: root.projectName
                    color: Theme.textPrimaryGlass
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.maximumWidth: root.isCompact ? 100 : 180
                }

                Rectangle {
                    visible: root.hasProject
                    Layout.minimumWidth: 0
                    Layout.preferredWidth: root.hasProject ? implicitWidth : 0
                    implicitWidth: statusText.implicitWidth + (root.isCompact ? Theme.spaceSmall : Theme.spaceMedium)
                    implicitHeight: 20
                    radius: 10
                    color: root.isSaved ? Theme.badgeEmeraldBg : Theme.badgeAmberBg
                    border.color: root.isSaved ? Theme.badgeEmeraldText : Theme.badgeAmberText
                    border.width: 1

                    Text {
                        id: statusText
                        anchors.centerIn: parent
                        text: root.isSaved ? (root.isCompact ? "✓" : "✓ Đã lưu") : (root.isCompact ? "●" : "● Chưa lưu")
                        color: root.isSaved ? Theme.badgeEmeraldText : Theme.badgeAmberText
                        font.pixelSize: 10
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

            // CỤM PHẢI: CÁC THAO TÁC CHÍNH (DẠNG VIÊN THUỐC)
            RowLayout {
                id: rightActionsRow
                objectName: "rightActionsRow"
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.isCompact ? Theme.spaceXs : Theme.spaceSmall
                z: 2

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
                    color: Theme.glassBorderSubtle
                    Layout.margins: Theme.spaceXs
                }

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
                    color: Theme.glassBorderSubtle
                    Layout.margins: Theme.spaceXs
                }

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

            // CỤM GIỮA: REFRACIVE LANGUAGE CAPSULE + AI MODEL MANAGER
            Item {
                id: centerCluster
                anchors.left: leftBrandingRow.right
                anchors.leftMargin: Theme.spaceSmall
                anchors.right: rightActionsRow.left
                anchors.rightMargin: Theme.spaceSmall
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                clip: true

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        id: langCapsule
                        visible: centerCluster.width >= 120
                        implicitHeight: 26
                        implicitWidth: langContent.implicitWidth + 20
                        radius: 13
                        color: Qt.rgba(1, 1, 1, 0.45)
                        border.color: Theme.glassBorderSpecularUpper
                        border.width: 1

                        RowLayout {
                            id: langContent
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: root.sourceLanguage
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.textOnLightPod
                            }
                            Text {
                                text: "➔"
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.accentSapphire
                            }
                            Text {
                                text: root.targetLanguage
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.accentSapphire
                            }
                        }
                    }

                    AppButton {
                        objectName: "btnModelManager"
                        visible: centerCluster.width >= 180
                        text: {
                            if (typeof modelController === "undefined") return "⚡ Mô hình AI ▼"
                            if (centerCluster.width < 320) return "⚡ Mô hình ▼"
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
    }
}
