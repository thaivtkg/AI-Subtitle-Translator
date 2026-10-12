import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Item {
    id: root
    property string emptyStateMode: "no_selection"
    signal openSrtClicked()
    signal openProjectClicked()

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.85, 520)
        implicitHeight: cardContent.implicitHeight + Theme.spaceLarge * 2
        radius: 12
        color: Theme.bgSurface
        border.color: Theme.border
        border.width: 1

        ColumnLayout {
            id: cardContent
            anchors.centerIn: parent
            width: parent.width - Theme.spaceLarge * 2
            spacing: Theme.spaceMedium

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "⚡ HƯỚNG DẪN THAO TÁC NHANH"
                color: Theme.accentCyan
                font.pixelSize: 14
                font.bold: true
                font.letterSpacing: 1.5
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Chọn một câu phụ đề bên trái để bắt đầu dịch"
                color: Theme.textSecondary
                font.pixelSize: 13
                Layout.bottomMargin: Theme.spaceSmall
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: Theme.spaceMedium
                columnSpacing: Theme.spaceLarge

                // Phím tắt 1
                RowLayout {
                    spacing: Theme.spaceSmall
                    Rectangle {
                        width: 32; height: 32; radius: 6; color: Theme.bgSurfaceSoft; border.color: Theme.border
                        Text { anchors.centerIn: parent; text: "T"; color: Theme.textPrimary; font.bold: true; font.pixelSize: 14 }
                    }
                    Text { text: "Dịch bằng AI"; color: Theme.textSecondary; font.pixelSize: 12 }
                }

                // Phím tắt 2
                RowLayout {
                    spacing: Theme.spaceSmall
                    Rectangle {
                        width: 32; height: 32; radius: 6; color: Theme.bgSurfaceSoft; border.color: Theme.border
                        Text { anchors.centerIn: parent; text: "↵"; color: Theme.textPrimary; font.bold: true; font.pixelSize: 16 }
                    }
                    Text { text: "Duyệt & Tới câu tiếp"; color: Theme.textSecondary; font.pixelSize: 12 }
                }

                // Phím tắt 3
                RowLayout {
                    spacing: Theme.spaceSmall
                    Rectangle {
                        width: 32; height: 32; radius: 6; color: Theme.bgSurfaceSoft; border.color: Theme.border
                        Text { anchors.centerIn: parent; text: "↑↓"; color: Theme.textPrimary; font.bold: true; font.pixelSize: 14 }
                    }
                    Text { text: "Điều hướng danh sách câu"; color: Theme.textSecondary; font.pixelSize: 12 }
                }

                // Phím tắt 4
                RowLayout {
                    spacing: Theme.spaceSmall
                    Rectangle {
                        width: 32; height: 32; radius: 6; color: Theme.bgSurfaceSoft; border.color: Theme.border
                        Text { anchors.centerIn: parent; text: "S"; color: Theme.textPrimary; font.bold: true; font.pixelSize: 14 }
                    }
                    Text { text: "Lưu dự án"; color: Theme.textSecondary; font.pixelSize: 12 }
                }
            }
        }
    }
}
