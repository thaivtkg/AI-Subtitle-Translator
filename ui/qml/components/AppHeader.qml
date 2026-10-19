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
    readonly property bool isCompact: width < 1180
    readonly property bool isMinimum: width < 1050

    signal openSrtClicked()
    signal openProjectClicked()
    signal saveClicked()
    signal exportClicked()
    signal modelManagerClicked()
    signal archetypeClicked()
    signal closeProjectClicked()

    implicitHeight: 48
    padding: 0

    background: Rectangle {
        color: "transparent"
    }

    contentItem: Item {
        // SEAMLESS LIQUID GLASS HEADER BAR
        Rectangle {
            id: headerCapsule
            anchors.fill: parent
            radius: 0
            color: Qt.rgba(1.0, 1.0, 1.0, 0.18)
            border.color: "transparent"
            clip: true

            // Bottom 1px glass divider line
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Theme.glassBorderSubtle
                antialiasing: false
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                acceptedButtons: Qt.LeftButton
                onPressed: Window.window.startSystemMove()
                onDoubleClicked: {
                    if (Window.window.visibility === Window.Maximized) Window.window.showNormal()
                    else Window.window.showMaximized()
                }
            }

            // CỤM TRÁI: LOGO STUDIO + TÊN DỰ ÁN
            RowLayout {
                id: leftBrandingRow
                objectName: "leftBrandingRow"
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spaceSmall

                Text {
                    text: root.isCompact ? "◈ Studio" : "◈ AI Subtitle Studio"
                    color: Theme.textPrimaryGlass
                    font.pixelSize: 13
                    font.bold: true
                }

                Rectangle {
                    implicitWidth: verText.implicitWidth + 12
                    implicitHeight: 18
                    radius: 9
                    color: Qt.rgba(1, 1, 1, 0.22)
                    border.color: Theme.glassBorderSpecularUpper
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter
                    Text {
                        id: verText
                        anchors.centerIn: parent
                        text: "v1.2 Liquid Glass"
                        color: Theme.textPrimaryGlass
                        font.pixelSize: 10
                        font.bold: true
                    }
                }

                Rectangle {
                    visible: root.hasProject && root.projectName !== "Workspace" && root.projectName !== "Untitled"
                    implicitWidth: 1
                    implicitHeight: 14
                    color: Theme.glassBorderSubtle
                    Layout.leftMargin: Theme.spaceXs
                    Layout.rightMargin: Theme.spaceXs
                }

                Text {
                    visible: root.hasProject && root.projectName !== "Workspace" && root.projectName !== "Untitled"
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

            // CỤM NÚT ĐIỀU KHIỂN CỬA SỔ WINDOWS 11 (ANCHORED TOP-RIGHT)
            RowLayout {
                id: windowControlsRow
                objectName: "windowControlsRow"
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                z: 5

                Button {
                    id: btnMinimize
                    objectName: "btnMinimize"
                    implicitWidth: 36
                    implicitHeight: 28
                    padding: 0
                    ToolTip.visible: hovered
                    ToolTip.text: "Thu nhỏ"
                    contentItem: Text {
                        text: "—"
                        color: Theme.textPrimaryGlass
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 8
                        color: btnMinimize.pressed ? Qt.rgba(1, 1, 1, 0.25) : (btnMinimize.hovered ? Qt.rgba(1, 1, 1, 0.15) : "transparent")
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                    onClicked: Window.window.showMinimized()
                }

                Button {
                    id: btnMaximize
                    objectName: "btnMaximize"
                    implicitWidth: 36
                    implicitHeight: 28
                    padding: 0
                    ToolTip.visible: hovered
                    ToolTip.text: Window.window.visibility === Window.Maximized ? "Khôi phục" : "Phóng to"
                    contentItem: Text {
                        text: Window.window.visibility === Window.Maximized ? "🗗" : "🗖"
                        color: Theme.textPrimaryGlass
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 8
                        color: btnMaximize.pressed ? Qt.rgba(1, 1, 1, 0.25) : (btnMaximize.hovered ? Qt.rgba(1, 1, 1, 0.15) : "transparent")
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                    onClicked: {
                        if (Window.window.visibility === Window.Maximized) Window.window.showNormal()
                        else Window.window.showMaximized()
                    }
                }

                Button {
                    id: btnClose
                    objectName: "btnClose"
                    implicitWidth: 36
                    implicitHeight: 28
                    padding: 0
                    ToolTip.visible: hovered
                    ToolTip.text: "Đóng"
                    contentItem: Text {
                        text: "✕"
                        color: btnClose.hovered ? "#FFFFFF" : Theme.textPrimaryGlass
                        font.pixelSize: 12
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 8
                        color: btnClose.pressed ? "#C42B1C" : (btnClose.hovered ? "#E81123" : "transparent")
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                    onClicked: Window.window.close()
                }
            }

            // CỤM PHẢI: CÁC THAO TÁC CHÍNH (DẠNG VIÊN THUỐC ĐẶT CẠNH WINDOW CONTROLS)
            RowLayout {
                id: rightActionsRow
                objectName: "rightActionsRow"
                anchors.right: windowControlsRow.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.isCompact ? Theme.spaceXs : Theme.spaceSmall
                z: 10
                // ẨN TOÀN BỘ KHI Ở MÀN HÌNH KHỞI ĐỘNG
                visible: root.hasProject

                // Ẩn Mở SRT và Đóng khỏi thanh Header để chống chật chội
                AppButton {
                    objectName: "btnOpenSrt"
                    visible: false
                    text: root.isCompact ? "SRT" : "📁 Mở SRT"
                    tooltip: "Mở hoặc đổi file SRT khác — Ctrl + O"
                    enabled: !root.projectMutationLocked
                    onClicked: root.openSrtClicked()
                }
                AppButton {
                    id: btnCloseProject
                    objectName: "btnCloseProject"
                    visible: false
                    text: root.isCompact ? "⌂" : "⌂ Đóng & Khởi động"
                    tooltip: "Đóng file phụ đề hiện tại và quay về màn hình khởi động — Ctrl + W"
                    isPrimary: false
                    isDarkGlass: true
                    enabled: !root.projectMutationLocked
                    onClicked: root.closeProjectClicked()
                }
                AppButton {
                    objectName: "btnOpenProject"
                    visible: false
                    text: root.isCompact ? "Dự án" : "Mở dự án"
                    tooltip: "Mở file dự án — Ctrl + Shift + O"
                    enabled: !root.projectMutationLocked
                    onClicked: root.openProjectClicked()
                }

                // CHỈ HIỂN THỊ 2 NÚT THỰC THI CHÍNH KHI ĐANG DỊCH
                HeaderBatchControl {
                    id: headerBatch
                    visible: true
                    sourceLanguage: root.sourceLanguage
                    targetLanguage: root.targetLanguage
                    storySummary: root.storySummary
                    isCompact: root.isCompact
                    currentSubtitleIndex: root.currentSubtitleIndex
                    selectedIndices: root.selectedIndices
                }

                AppButton {
                    objectName: "btnSave"
                    visible: false
                    text: "💾 Lưu"
                    tooltip: "Lưu dự án — Ctrl + S"
                    enabled: root.hasProject && !root.isSaved
                    onClicked: root.saveClicked()
                }
                AppButton {
                    objectName: "btnExport"
                    visible: true
                    text: root.isCompact ? "Xuất" : "💾 Xuất SRT"
                    tooltip: "Xuất file phụ đề SRT — Ctrl + Shift + S"
                    isPrimary: false
                    isDarkGlass: true
                    enabled: root.hasProject && root.hasProjectData
                    onClicked: root.exportClicked()
                }
            }

            // CỤM GIỮA: REFRACIVE LANGUAGE CAPSULE + AI MODEL MANAGER
            Item {
                id: centerCluster
                anchors.left: leftBrandingRow.right
                anchors.leftMargin: 4
                anchors.right: rightActionsRow.left
                anchors.rightMargin: 4
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                clip: true

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        id: langCapsule
                        visible: root.hasProject && centerCluster.width >= 120
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
                                text: root.sourceLanguage === "English" ? "🇬🇧 English" : root.sourceLanguage
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
                                text: root.targetLanguage === "Vietnamese" ? "🇻🇳 Tiếng Việt" : root.targetLanguage
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.accentSapphire
                            }
                        }
                    }

                    Rectangle {
                        id: archetypeHeaderCapsule
                        objectName: "archetypeHeaderCapsule"
                        visible: root.hasProject && typeof projectController !== "undefined" && centerCluster.width >= 280
                        implicitHeight: 26
                        implicitWidth: archetypeHeaderRow.implicitWidth + 20
                        radius: 13
                        color: archetypeHeaderMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.65) : Qt.rgba(1, 1, 1, 0.45)
                        border.color: Theme.glassBorderSpecularUpper
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            id: archetypeHeaderRow
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: {
                                    if (typeof projectController === "undefined") return "🎭"
                                    var list = projectController.archetypeList || []
                                    for (var i = 0; i < list.length; i++) {
                                        if (list[i].id === projectController.activeArchetype) {
                                            return list[i].icon || "🎭"
                                        }
                                    }
                                    return "🎭"
                                }
                                font.pixelSize: 12
                            }

                            Text {
                                text: {
                                    if (typeof projectController === "undefined") return "Tự do"
                                    var pair = projectController.activePronounPair || ""
                                    return pair.startsWith("Tự do") ? "Tự do" : pair
                                }
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.textOnLightPod
                            }
                        }

                        ToolTip.visible: archetypeHeaderMouse.containsMouse
                        ToolTip.text: typeof projectController !== "undefined"
                                      ? ("Thể loại: " + projectController.archetypeDisplayLabel + " (" + projectController.activePronounPair + ") - Click để tùy chỉnh")
                                      : ""

                        MouseArea {
                            id: archetypeHeaderMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.archetypeClicked()
                                if (typeof contextTabs !== "undefined") {
                                    contextTabs.setCurrentIndex(1)
                                }
                            }
                        }
                    }

                    AppButton {
                        id: btnModelManager
                        objectName: "btnModelManager"
                        visible: centerCluster.width >= 140
                        Layout.maximumWidth: 175
                        text: {
                            if (typeof modelController === "undefined") return "🔮 Qwen 2.5 3B ▼"
                            var name = modelController.activeModelDisplayName || "Mô hình AI"
                            var shortName = name.split('/')[0].replace(/\s+(?:Instruct|Distill|Default|IT).*$/i, "").replace(/\s*\(.*\)$/, "").trim()
                            if (centerCluster.width < 280) {
                                if (shortName.length > 10) shortName = shortName.substring(0, 10) + "…"
                            } else {
                                if (shortName.length > 14) shortName = shortName.substring(0, 14) + "…"
                            }
                            return "🔮 " + shortName + " ▼"
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
