import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import "../theme"

ToolBar {
    id: root
    property string projectName: "Chưa mở dự án"
    property bool isSaved: true
    
    signal openSrtClicked()
    signal openProjectClicked()
    signal saveClicked()
    signal exportClicked()

    // 1. CỐ ĐỊNH CHIỀU CAO HEADER ĐỂ CHỐNG SẬP VIỀN
    implicitHeight: 48
    leftPadding: Theme.spaceMedium
    rightPadding: 0 // Cho phép các nút điều khiển bám sát lề phải

    background: Rectangle { 
        color: Theme.bgApp
        
        // Đường viền dưới giờ sẽ nằm chuẩn xác ở đáy Header
        Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: Theme.border }

        // VÙNG NHẬN DIỆN CHUỘT ĐỂ KÉO CỬA SỔ
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onPressed: Window.window.startSystemMove() 
        }
    }

    // 2. GÁN ROWLAYOUT LÀM CONTENT ITEM CHUẨN CỦA QML
    contentItem: RowLayout {
        spacing: Theme.spaceMedium

        // BRANDING
        Text { text: "◈ AI Subtitle Translator"; color: Theme.textPrimary; font.family: Theme.fontUI; font.pixelSize: Theme.fontSizeTitle; font.bold: true }
        
        // Thanh phân cách dọc (Bo lề trên dưới để đẹp hơn)
        Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; Layout.topMargin: 12; Layout.bottomMargin: 12; color: Theme.border }

        // PROJECT STATE
        RowLayout {
            spacing: Theme.spaceSmall
            Text { text: root.projectName; color: Theme.textPrimary; font.family: Theme.fontUI; font.pixelSize: Theme.fontSizeBody }
            Text { text: root.isSaved ? "✓ Saved" : "● Unsaved changes"; color: root.isSaved ? Theme.textSecondary : Theme.warning; font.family: Theme.fontUI; font.pixelSize: Theme.fontSizeSmall }
        }

        Item { Layout.fillWidth: true } // Spacer

        // ACTIONS
        AppButton { text: "Open SRT"; onClicked: root.openSrtClicked() }
        AppButton { text: "Open Project"; onClicked: root.openProjectClicked() }
        AppButton { text: "Save"; onClicked: root.saveClicked() }
        
        Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; Layout.topMargin: 12; Layout.bottomMargin: 12; color: Theme.border }
        
        AppButton { text: "Export SRT"; isPrimary: true; onClicked: root.exportClicked() }

        // CỤM NÚT WINDOW CONTROLS (Nằm chính xác ở góc phải)
        RowLayout {
            spacing: 0
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: Theme.spaceMedium

            // Nút Minimize
            Button {
                implicitWidth: 46; implicitHeight: 48
                contentItem: Text { text: "—"; color: Theme.textSecondary; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.bold: true }
                background: Rectangle { color: parent.hovered ? Theme.bgSurfaceSoft : "transparent" }
                onClicked: Window.window.showMinimized()
            }
            
            // Nút Maximize / Restore
            Button {
                implicitWidth: 46; implicitHeight: 48
                contentItem: Text { text: Window.window.visibility === Window.Maximized ? "🗗" : "🗖"; color: Theme.textSecondary; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                background: Rectangle { color: parent.hovered ? Theme.bgSurfaceSoft : "transparent" }
                onClicked: {
                    if (Window.window.visibility === Window.Maximized) Window.window.showNormal()
                    else Window.window.showMaximized()
                }
            }
            
            // Nút Close
            Button {
                implicitWidth: 46; implicitHeight: 48
                contentItem: Text { text: "✕"; color: parent.hovered ? "#FFFFFF" : Theme.textSecondary; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                background: Rectangle { color: parent.hovered ? Theme.danger : "transparent" }
                onClicked: Window.window.close()
            }
        }
    }
}