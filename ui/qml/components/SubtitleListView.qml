import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

ColumnLayout {
    id: root
    spacing: 0

    property alias model: subListView.model
    property alias currentIndex: subListView.currentIndex
    property alias count: subListView.count

    // Biến trạng thái để Lọc
    property string currentFilter: "ALL" // ALL, PENDING, DONE

    // --- 1. PANEL HEADER ---
    Rectangle {
        Layout.fillWidth: true; Layout.preferredHeight: 36; color: Theme.bgSurface
        RowLayout {
            anchors.fill: parent; anchors.margins: Theme.spaceMedium
            Text { text: "SUBTITLES"; color: Theme.textSecondary; font.family: Theme.fontUI; font.pixelSize: Theme.fontSizeSmall; font.bold: true }
            Item { Layout.fillWidth: true }
            Text { text: subListView.count + " subtitles"; color: Theme.textMuted; font.family: Theme.fontUI; font.pixelSize: Theme.fontSizeSmall }
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
    }

    // --- 2. TOOLBAR (Search & Filter) ---
    Rectangle {
        Layout.fillWidth: true; Layout.preferredHeight: 70; color: Theme.bgSurface
        
        ColumnLayout {
            anchors.fill: parent; spacing: 0
            
            // Ô Tìm kiếm
            TextField {
                id: searchInput
                Layout.fillWidth: true
                Layout.margins: Theme.spaceSmall
                placeholderText: "🔍 Search text..."
                font.family: Theme.fontUI
                font.pixelSize: Theme.fontSizeBody
                color: Theme.textPrimary
                background: Rectangle {
                    color: Theme.bgApp; radius: Theme.radius
                    border.color: parent.activeFocus ? Theme.accentSecondary : Theme.border
                }
            }
            
            // Bộ lọc (Segmented Control phong cách VS Code)
            RowLayout {
                Layout.fillWidth: true; Layout.margins: Theme.spaceSmall; Layout.topMargin: 0
                spacing: Theme.spaceMedium
                
                Text {
                    text: "ALL"
                    color: root.currentFilter === "ALL" ? Theme.textPrimary : Theme.textMuted
                    font.family: Theme.fontUI; font.pixelSize: Theme.fontSizeSmall; font.bold: true
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.currentFilter = "ALL" }
                }
                Text {
                    text: "PENDING"
                    color: root.currentFilter === "PENDING" ? Theme.accentSecondary : Theme.textMuted
                    font.family: Theme.fontUI; font.pixelSize: Theme.fontSizeSmall; font.bold: true
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.currentFilter = "PENDING" }
                }
                Text {
                    text: "DONE"
                    color: root.currentFilter === "DONE" ? Theme.accentPrimary : Theme.textMuted
                    font.family: Theme.fontUI; font.pixelSize: Theme.fontSizeSmall; font.bold: true
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.currentFilter = "DONE" }
                }
            }
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
    }

    // --- 3. HIGH DENSITY LIST ---
    ListView {
        id: subListView
        Layout.fillWidth: true; Layout.fillHeight: true
        clip: true
        
        Component.onCompleted: { if (count > 0) translationController.loadSubtitle(0) }
        onCurrentIndexChanged: { if (currentIndex >= 0) translationController.loadSubtitle(currentIndex) }

        delegate: Rectangle {
            id: delegateItem
            width: subListView.width
            
            // LOGIC LỌC (FILTER & SEARCH) NGAY TRÊN QML
            property string sText: searchInput.text.toLowerCase()
            property bool matchSearch: sText === "" || originalText.toLowerCase().includes(sText) || (translationText !== undefined && translationText.toLowerCase().includes(sText))
            property bool matchFilter: root.currentFilter === "ALL" || 
                                     (root.currentFilter === "PENDING" && (status === "PENDING" || status === undefined)) ||
                                     (root.currentFilter === "DONE" && (status === "ACCEPTED" || status === "TRANSLATED" || status === "EDITED"))
            
            visible: matchSearch && matchFilter
            height: visible ? 60 : 0 // Thu gọn thẻ nếu không khớp điều kiện
            
            property bool isSelected: ListView.isCurrentItem
            color: isSelected ? Theme.bgSurfaceElevated : (mouseArea.containsMouse ? Theme.bgSurfaceSoft : "transparent")
            
            Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 3; color: isSelected ? Theme.accentSecondary : "transparent" }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.bgApp; visible: delegateItem.visible }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: Theme.spaceSmall; anchors.leftMargin: Theme.spaceMedium; spacing: 2
                visible: delegateItem.visible

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "#" + subIndex; color: Theme.textMuted; font.family: Theme.fontUI; font.pixelSize: Theme.fontSizeSmall }
                    Text { text: " • " + startTime + " → " + endTime; color: Theme.textMuted; font.family: Theme.fontUI; font.pixelSize: Theme.fontSizeSmall }
                    Item { Layout.fillWidth: true }
                    StatusBadge { status: model.status !== undefined ? model.status : "PENDING" }
                }

                Text { 
                    text: status === "ACCEPTED" ? translationText : originalText
                    color: isSelected ? Theme.textPrimary : Theme.textSecondary
                    font.family: Theme.fontUI; font.pixelSize: Theme.fontSizeBody
                    elide: Text.ElideRight; Layout.fillWidth: true 
                }
            }

            MouseArea { 
                id: mouseArea
                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: subListView.currentIndex = index 
            }
        }

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        
        Text {
            anchors.centerIn: parent
            text: "Không có dữ liệu phù hợp"
            color: Theme.textDisabled
            font.family: Theme.fontUI
            font.pixelSize: Theme.fontSizeBody
            visible: subListView.count === 0 || subListView.contentHeight === 0
        }
    }
}