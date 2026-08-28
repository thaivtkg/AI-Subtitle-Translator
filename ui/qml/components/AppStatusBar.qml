import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Rectangle {
    id: root
    Layout.fillWidth: true
    height: 28
    color: Theme.bgSurface // Nền đồng nhất với Header
    
    // Viền trên phân cách với Workspace
    Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Theme.border }

    // --- CÁC BIẾN NHẬN DỮ LIỆU TỪ MAIN ---
    property int totalItems: 0
    property int acceptedItems: 0
    property string aiState: "Ready"
    
    property real vramUsage: 3.5 // GB (Mock data để test thanh cảnh báo)
    property real vramTotal: 4.0 // GB (RTX 3050)

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spaceSmall
        anchors.leftMargin: Theme.spaceMedium
        anchors.rightMargin: Theme.spaceMedium
        spacing: Theme.spaceLarge

        // --- 1. TIẾN TRÌNH DỊCH THUẬT (PROGRESS BAR) ---
        RowLayout {
            spacing: Theme.spaceSmall
            Text { text: "✓"; color: Theme.textMuted; font.pixelSize: Theme.fontSizeBadge }
            Text {
                text: acceptedItems + " / " + totalItems + " Accepted"
                color: Theme.textSecondary
                font.family: Theme.fontUI
                font.pixelSize: Theme.fontSizeSmall
            }
            // Vạch phần trăm
            Rectangle {
                width: 100; height: 4; radius: 2; color: Theme.bgApp
                Rectangle {
                    height: parent.height; radius: 2
                    width: totalItems > 0 ? parent.width * (acceptedItems / totalItems) : 0
                    color: Theme.accentPrimary
                    Behavior on width { NumberAnimation { duration: 300 } }
                }
            }
            Text {
                text: totalItems > 0 ? Math.round((acceptedItems/totalItems)*100) + "%" : "0%"
                color: Theme.textMuted
                font.family: Theme.fontUI
                font.pixelSize: Theme.fontSizeSmall
            }
        }

        Item { Layout.fillWidth: true } // Đẩy các phần tử còn lại sang phải

        // --- 2. TRẠNG THÁI AI ENGINE ---
        RowLayout {
            spacing: Theme.spaceXs
            Text {
                text: "AI Engine:"
                color: Theme.textMuted
                font.family: Theme.fontUI
                font.pixelSize: Theme.fontSizeSmall
            }
            Text {
                text: root.aiState
                color: root.aiState === "Translating..." ? Theme.accentSecondary : Theme.textSecondary
                font.family: Theme.fontUI
                font.pixelSize: Theme.fontSizeSmall
                font.bold: root.aiState === "Translating..."
            }
        }

        Rectangle { width: 1; height: 14; color: Theme.border } // Dấu gạch đứng phân cách

        // --- 3. VẠCH CẢNH BÁO VRAM (RTX 3050) ---
        RowLayout {
            spacing: Theme.spaceSmall
            Text {
                text: "VRAM:"
                color: Theme.textMuted
                font.family: Theme.fontUI
                font.pixelSize: Theme.fontSizeSmall
            }
            Text {
                text: vramUsage.toFixed(1) + " / " + vramTotal.toFixed(1) + " GB"
                color: Theme.textSecondary
                font.family: Theme.fontUI
                font.pixelSize: Theme.fontSizeSmall
            }
            // Vạch VRAM đổi màu động
            Rectangle {
                width: 80; height: 6; radius: 3; color: Theme.bgApp
                Rectangle {
                    height: parent.height; radius: 3
                    width: parent.width * (vramUsage / vramTotal)
                    
                    // Logic màu: >85% Đỏ (Danger), >70% Vàng (Warning), còn lại Xanh (Primary)
                    color: (vramUsage / vramTotal) > 0.85 ? Theme.danger : 
                          ((vramUsage / vramTotal) > 0.70 ? Theme.warning : Theme.accentPrimary)
                    
                    Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 500 } }
                }
            }
        }
    }
}