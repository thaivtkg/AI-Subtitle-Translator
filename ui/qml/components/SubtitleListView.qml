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

    property string currentFilter: "ALL"

    // --- 1. HEADER ---
    Rectangle {
        Layout.fillWidth: true; Layout.preferredHeight: 36; color: Theme.bgSurface
        RowLayout {
            anchors.fill: parent; anchors.margins: Theme.space16
            Text { text: "SUBTITLES"; color: Theme.textSecondary; font.family: Theme.fontUI; font.pixelSize: Theme.fontCaption; font.bold: true }
            Item { Layout.fillWidth: true }
            Text { text: subListView.count + " subtitles"; color: Theme.textMuted; font.family: Theme.fontUI; font.pixelSize: Theme.fontCaption }
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
    }

    // --- 2. SEARCH & FILTER ---
    Rectangle {
        Layout.fillWidth: true; Layout.preferredHeight: 76; color: Theme.bgSurface
        
        ColumnLayout {
            anchors.fill: parent; spacing: 0
            
            TextField {
                id: searchInput
                Layout.fillWidth: true
                Layout.margins: Theme.space8
                placeholderText: "🔍 Search text..."
                font.family: Theme.fontUI
                font.pixelSize: Theme.fontBody
                color: Theme.textPrimary
                background: Rectangle {
                    color: Theme.bgApp; radius: Theme.radius
                    border.color: parent.activeFocus ? Theme.accentSecondary : Theme.border
                }
            }
            
            RowLayout {
                Layout.fillWidth: true; Layout.margins: Theme.space8; Layout.topMargin: 0
                spacing: Theme.space12
                
                // Các bộ lọc chuẩn State Machine
                Repeater {
                    model: ["ALL", "PENDING", "TRANSLATED", "ACCEPTED"]
                    delegate: Text {
                        text: modelData
                        color: root.currentFilter === modelData ? Theme.textPrimary : Theme.textMuted
                        font.family: Theme.fontUI; font.pixelSize: Theme.fontCaption; font.bold: true
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.currentFilter = modelData }
                    }
                }
            }
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
    }

    // --- 3. COMPACT LIST ---
    ListView {
        id: subListView
        Layout.fillWidth: true; Layout.fillHeight: true
        clip: true
        
        Component.onCompleted: { if (count > 0) translationController.loadSubtitle(0) }
        onCurrentIndexChanged: { if (currentIndex >= 0) translationController.loadSubtitle(currentIndex) }

        delegate: Rectangle {
            id: delegateItem
            width: subListView.width
            
            property string sText: searchInput.text.toLowerCase()
            property bool matchSearch: sText === "" || originalText.toLowerCase().includes(sText) || (translationText !== undefined && translationText.toLowerCase().includes(sText))
            property bool matchFilter: root.currentFilter === "ALL" || 
                                     (root.currentFilter === "PENDING" && (status === "PENDING" || status === undefined)) ||
                                     (root.currentFilter === "TRANSLATED" && (status === "TRANSLATED" || status === "EDITED")) ||
                                     (root.currentFilter === "ACCEPTED" && status === "ACCEPTED")
            
            visible: matchSearch && matchFilter
            height: visible ? 56 : 0 // Nén gọn hơn
            
            property bool isSelected: ListView.isCurrentItem
            color: isSelected ? Theme.bgSurfaceElevated : (mouseArea.containsMouse ? Theme.bgSurfaceSoft : "transparent")
            
            Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 3; color: isSelected ? Theme.accentSecondary : "transparent" }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; visible: delegateItem.visible; opacity: 0.5 }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: Theme.space8; anchors.leftMargin: Theme.space16; spacing: 2
                visible: delegateItem.visible

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "#" + subIndex; color: Theme.textMuted; font.family: Theme.fontUI; font.pixelSize: Theme.fontCaption }
                    Text { text: " • " + startTime; color: Theme.textMuted; font.family: Theme.fontUI; font.pixelSize: Theme.fontCaption }
                    Item { Layout.fillWidth: true }
                    StatusBadge { status: model.status !== undefined ? model.status : "PENDING" }
                }

                Text { 
                    text: originalText
                    color: isSelected ? Theme.textPrimary : Theme.textSecondary
                    font.family: Theme.fontUI; font.pixelSize: Theme.fontBody
                    elide: Text.ElideRight; Layout.fillWidth: true 
                }
            }

            MouseArea { 
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
            font.pixelSize: Theme.fontBody
            visible: subListView.count === 0 || subListView.contentHeight === 0
        }
    }
}