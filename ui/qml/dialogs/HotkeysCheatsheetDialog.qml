import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import "../theme"

Dialog {
    id: root
    objectName: "hotkeysDialog"

    title: ""
    modal: true
    dim: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    anchors.centerIn: Overlay.overlay

    width: Math.min(560, Overlay.overlay ? Overlay.overlay.width - 32 : 560)
    height: Math.min(560, Overlay.overlay ? Overlay.overlay.height - 32 : 560)
    padding: 0

    Shortcut {
        sequence: "F1"
        enabled: root.visible
        onActivated: root.close()
    }

    background: Rectangle {
        color: Qt.rgba(0.97, 0.96, 0.99, 0.95)
        radius: 18
        border.color: Theme.glassBorderSpecularUpper
        border.width: 1.5

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 0.8
            shadowColor: Qt.rgba(0, 0, 0, 0.35)
        }
    }

    component KeyCap: Rectangle {
        property alias text: keyText.text
        implicitHeight: 22
        implicitWidth: keyText.implicitWidth + 12
        radius: 6
        color: Qt.rgba(1.0, 1.0, 1.0, 0.95)
        border.color: Qt.rgba(0.06, 0.09, 0.16, 0.15)
        border.width: 1

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 0.15
            shadowVerticalOffset: 1
            shadowColor: Qt.rgba(0, 0, 0, 0.06)
        }

        Text {
            id: keyText
            anchors.centerIn: parent
            font.pixelSize: 11
            font.bold: true
            color: "#0F172A"
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
            implicitHeight: 48
            color: Qt.rgba(1.0, 1.0, 1.0, 0.70)
            radius: 18

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 16
                color: Qt.rgba(1.0, 1.0, 1.0, 0.70)
            }
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Qt.rgba(0, 0, 0, 0.08)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 16
                spacing: 8

                Text {
                    text: "⌨"
                    font.pixelSize: 16
                }

                Text {
                    text: "BẢNG TRA CỨU PHÍM TẮT NHANH (PRO CAT HOTKEYS)"
                    color: "#0F172A"
                    font.pixelSize: 13
                    font.bold: true
                    Layout.fillWidth: true
                }

                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 28
                    radius: 8
                    color: closeMouse.pressed ? Qt.rgba(232, 17, 35, 0.2) : (closeMouse.containsMouse ? Qt.rgba(232, 17, 35, 0.12) : Qt.rgba(15, 23, 42, 0.06))
                    border.color: closeMouse.containsMouse ? "#E81123" : Qt.rgba(15, 23, 42, 0.12)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: closeMouse.containsMouse ? "#E81123" : "#0F172A"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
            }
        }

        // ==========================================
        // CONTENT SCROLLVIEW
        // ==========================================
        ScrollView {
            id: cheatsheetScroll
            objectName: "cheatsheetScroll"
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            topPadding: 16
            bottomPadding: 20
            leftPadding: 20
            rightPadding: 20
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                width: cheatsheetScroll.availableWidth
                spacing: 14

                // --- GROUP 1: BIÊN DỊCH & DUYỆT BÀI ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "✦ BIÊN DỊCH & DUYỆT BÀI (PRO KEY-FLOW)"
                        color: Theme.accentSapphire
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 0.5
                    }

                    // Row: Ctrl + Enter
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        RowLayout {
                            implicitWidth: 175
                            spacing: 4
                            KeyCap { text: "Ctrl" }
                            Text { text: "+"; color: "#64748B"; font.bold: true; font.pixelSize: 11 }
                            KeyCap { text: "Enter" }
                            Item { Layout.fillWidth: true }
                        }
                        Text {
                            text: "Duyệt câu hiện tại & Nhảy câu kế tiếp"
                            color: "#1E293B"
                            font.pixelSize: 12
                            font.bold: true
                            Layout.fillWidth: true
                        }
                    }

                    // Row: Ctrl + Shift + Enter
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        RowLayout {
                            implicitWidth: 175
                            spacing: 4
                            KeyCap { text: "Ctrl" }
                            Text { text: "+"; color: "#64748B"; font.bold: true; font.pixelSize: 11 }
                            KeyCap { text: "Shift" }
                            Text { text: "+"; color: "#64748B"; font.bold: true; font.pixelSize: 11 }
                            KeyCap { text: "Enter" }
                            Item { Layout.fillWidth: true }
                        }
                        Text {
                            text: "Kích hoạt dịch AI (Pro Flow)"
                            color: "#1E293B"
                            font.pixelSize: 12
                            font.bold: true
                            Layout.fillWidth: true
                        }
                    }

                    // Row: Ctrl + T
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        RowLayout {
                            implicitWidth: 175
                            spacing: 4
                            KeyCap { text: "Ctrl" }
                            Text { text: "+"; color: "#64748B"; font.bold: true; font.pixelSize: 11 }
                            KeyCap { text: "T" }
                            Item { Layout.fillWidth: true }
                        }
                        Text {
                            text: "Kích hoạt dịch AI (Kinh điển)"
                            color: "#1E293B"
                            font.pixelSize: 12
                            Layout.fillWidth: true
                        }
                    }

                    // Row: Ctrl + G
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        RowLayout {
                            implicitWidth: 175
                            spacing: 4
                            KeyCap { text: "Ctrl" }
                            Text { text: "+"; color: "#64748B"; font.bold: true; font.pixelSize: 11 }
                            KeyCap { text: "G" }
                            Item { Layout.fillWidth: true }
                        }
                        Text {
                            text: "Ghim nhanh từ bôi đen vào Glossary"
                            color: "#1E293B"
                            font.pixelSize: 12
                            Layout.fillWidth: true
                        }
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(0, 0, 0, 0.06)
                }

                // --- GROUP 2: ĐIỀU HƯỚNG & CÔNG CỤ ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "✦ ĐIỀU HƯỚNG & CÔNG CỤ (NAVIGATION & TOOLS)"
                        color: Theme.accentSapphire
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 0.5
                    }

                    // Row: Alt + Up / Alt + Down
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        RowLayout {
                            implicitWidth: 175
                            spacing: 4
                            KeyCap { text: "Alt" }
                            Text { text: "+"; color: "#64748B"; font.bold: true; font.pixelSize: 11 }
                            KeyCap { text: "▲ / ▼" }
                            Item { Layout.fillWidth: true }
                        }
                        Text {
                            text: "Di chuyển lên / xuống giữa các câu"
                            color: "#1E293B"
                            font.pixelSize: 12
                            Layout.fillWidth: true
                        }
                    }

                    // Row: Ctrl + H
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        RowLayout {
                            implicitWidth: 175
                            spacing: 4
                            KeyCap { text: "Ctrl" }
                            Text { text: "+"; color: "#64748B"; font.bold: true; font.pixelSize: 11 }
                            KeyCap { text: "H" }
                            Item { Layout.fillWidth: true }
                        }
                        Text {
                            text: "Bật / Tắt thanh Tìm kiếm & Thay thế"
                            color: "#1E293B"
                            font.pixelSize: 12
                            Layout.fillWidth: true
                        }
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(0, 0, 0, 0.06)
                }

                // --- GROUP 3: QUẢN LÝ TỆP & DỰ ÁN ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "✦ QUẢN LÝ TỆP & DỰ ÁN (FILE & PROJECT)"
                        color: Theme.accentSapphire
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 0.5
                    }

                    // Row: Ctrl + O
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        RowLayout {
                            implicitWidth: 175
                            spacing: 4
                            KeyCap { text: "Ctrl" }
                            Text { text: "+"; color: "#64748B"; font.bold: true; font.pixelSize: 11 }
                            KeyCap { text: "O" }
                            Item { Layout.fillWidth: true }
                        }
                        Text {
                            text: "Mở file phụ đề SRT gốc"
                            color: "#1E293B"
                            font.pixelSize: 12
                            Layout.fillWidth: true
                        }
                    }

                    // Row: Ctrl + Shift + O
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        RowLayout {
                            implicitWidth: 175
                            spacing: 4
                            KeyCap { text: "Ctrl" }
                            Text { text: "+"; color: "#64748B"; font.bold: true; font.pixelSize: 11 }
                            KeyCap { text: "Shift" }
                            Text { text: "+"; color: "#64748B"; font.bold: true; font.pixelSize: 11 }
                            KeyCap { text: "O" }
                            Item { Layout.fillWidth: true }
                        }
                        Text {
                            text: "Mở file dự án .aisrt"
                            color: "#1E293B"
                            font.pixelSize: 12
                            Layout.fillWidth: true
                        }
                    }

                    // Row: Ctrl + S
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        RowLayout {
                            implicitWidth: 175
                            spacing: 4
                            KeyCap { text: "Ctrl" }
                            Text { text: "+"; color: "#64748B"; font.bold: true; font.pixelSize: 11 }
                            KeyCap { text: "S" }
                            Item { Layout.fillWidth: true }
                        }
                        Text {
                            text: "Lưu dự án / Đồng bộ trực tiếp về Studio"
                            color: "#1E293B"
                            font.pixelSize: 12
                            Layout.fillWidth: true
                        }
                    }

                    // Row: Ctrl + Shift + S
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        RowLayout {
                            implicitWidth: 175
                            spacing: 4
                            KeyCap { text: "Ctrl" }
                            Text { text: "+"; color: "#64748B"; font.bold: true; font.pixelSize: 11 }
                            KeyCap { text: "Shift" }
                            Text { text: "+"; color: "#64748B"; font.bold: true; font.pixelSize: 11 }
                            KeyCap { text: "S" }
                            Item { Layout.fillWidth: true }
                        }
                        Text {
                            text: "Xuất file phụ đề SRT"
                            color: "#1E293B"
                            font.pixelSize: 12
                            Layout.fillWidth: true
                        }
                    }

                    // Row: Ctrl + W
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        RowLayout {
                            implicitWidth: 175
                            spacing: 4
                            KeyCap { text: "Ctrl" }
                            Text { text: "+"; color: "#64748B"; font.bold: true; font.pixelSize: 11 }
                            KeyCap { text: "W" }
                            Item { Layout.fillWidth: true }
                        }
                        Text {
                            text: "Đóng dự án hiện tại"
                            color: "#1E293B"
                            font.pixelSize: 12
                            Layout.fillWidth: true
                        }
                    }

                    // Row: F1
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        RowLayout {
                            implicitWidth: 175
                            spacing: 4
                            KeyCap { text: "F1" }
                            Item { Layout.fillWidth: true }
                        }
                        Text {
                            text: "Bật / Đóng bảng phím tắt này"
                            color: "#1E293B"
                            font.pixelSize: 12
                            font.bold: true
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }
}
