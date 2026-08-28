import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

ListView {
    id: subListView
    clip: true
    spacing: Theme.spaceSmall
    
    // Margins để danh sách không dính sát vào viền
    topMargin: Theme.spaceSmall
    bottomMargin: Theme.spaceSmall
    leftMargin: Theme.spaceSmall
    rightMargin: Theme.spaceSmall

    // Tự động load câu đầu tiên khi có dữ liệu
    Component.onCompleted: {
        if (count > 0) translationController.loadSubtitle(0)
    }
    onCurrentIndexChanged: {
        if (currentIndex >= 0) translationController.loadSubtitle(currentIndex)
    }

    delegate: Rectangle {
        width: subListView.width - Theme.spaceSmall * 2
        height: 85
        radius: Theme.radius
        
        // Màu nền: Nếu đang chọn thì sáng lên, nếu hover thì nổi nhẹ, bình thường thì chìm
        property bool isSelected: ListView.isCurrentItem
        
        color: isSelected ? Theme.bgSurfaceSoft : (mouseArea.containsMouse ? Theme.bgSurfaceElevated : Theme.bgApp)
        
        // Viền: Đang chọn thì viền màu Cyan, nếu đã ACCEPTED mà được chọn thì viền Xanh lá
        border.color: isSelected ? (status === "ACCEPTED" ? Theme.success : Theme.accentCyan) : Theme.border
        border.width: isSelected ? 2 : 1
        
        Behavior on color { ColorAnimation { duration: Theme.animDuration } }
        Behavior on border.color { ColorAnimation { duration: Theme.animDuration } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spaceMedium
            spacing: Theme.spaceXs

            RowLayout {
                Layout.fillWidth: true
                Text { 
                    text: "#" + subIndex + " | " + startTime + " → " + endTime
                    color: Theme.textMuted
                    font.pixelSize: 11 
                    Layout.fillWidth: true
                }
                StatusBadge { 
                    status: model.status !== undefined ? model.status : "PENDING" 
                }
            }

            Text { 
                // Logic Phase 1: Chưa duyệt hiện bản gốc, duyệt rồi hiện bản dịch
                text: status === "ACCEPTED" ? translationText : originalText
                color: isSelected ? Theme.textPrimary : Theme.textSecondary
                font.pixelSize: 14
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true 
            }
        }

        MouseArea { 
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: subListView.currentIndex = index 
        }
    }

    // Thanh cuộn (Scrollbar)
    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
    }
    Text {
        anchors.centerIn: parent
        text: "📁 Mở file SRT hoặc Project\nđể bắt đầu làm việc."
        color: Theme.textDisabled
        font.pixelSize: 14
        horizontalAlignment: Text.AlignHCenter
        lineHeight: 1.5
        visible: subListView.count === 0 // Chỉ hiện khi chưa có data
    }
}   