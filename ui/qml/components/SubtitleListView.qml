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

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        color: Theme.bgSurface

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spaceMedium
            anchors.rightMargin: Theme.spaceMedium
            Text { text: "SUBTITLES"; color: Theme.textSecondary; font.pixelSize: 12; font.bold: true }
            Item { Layout.fillWidth: true }
            Text { text: subListView.count + " items"; color: Theme.textMuted; font.pixelSize: 12 }
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 84
        color: Theme.bgSurface

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            TextField {
                id: searchInput
                Layout.fillWidth: true
                Layout.margins: Theme.spaceSmall
                Layout.bottomMargin: Theme.spaceXs
                placeholderText: "🔍 Search text..."
                font.pixelSize: 14
                color: Theme.textPrimary
                rightPadding: 30
                background: Rectangle {
                    color: Theme.bgApp
                    radius: Theme.radius
                    border.color: searchInput.activeFocus ? Theme.accentCyan : Theme.border
                }
                Button {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28; height: 28
                    visible: searchInput.text.length > 0
                    contentItem: Text { text: "✕"; color: Theme.textMuted; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: null
                    onClicked: searchInput.text = ""
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.spaceSmall
                Layout.rightMargin: Theme.spaceSmall
                Layout.bottomMargin: Theme.spaceSmall
                spacing: Theme.spaceSmall
                Repeater {
                    model: ["ALL", "PENDING", "TRANSLATED", "ACCEPTED"]
                    delegate: Text {
                        text: modelData
                        color: root.currentFilter === modelData ? Theme.textPrimary : Theme.textMuted
                        font.pixelSize: 12
                        font.bold: true
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: -4
                            width: parent.width
                            height: 2
                            color: Theme.accentCyan
                            visible: root.currentFilter === modelData
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentFilter = modelData
                        }
                    }
                }
            }
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
    }

    ListView {
        id: subListView
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Component.onCompleted: { if (count > 0) translationController.loadSubtitle(0) }
        onCurrentIndexChanged: { if (currentIndex >= 0) translationController.loadSubtitle(currentIndex) }

        delegate: Rectangle {
            id: delegateItem
            width: subListView.width
            property string normalizedStatus: String(status || "PENDING").toUpperCase()
            property string searchText: searchInput.text.toLowerCase()
            property bool matchSearch: searchText === "" || String(originalText || "").toLowerCase().includes(searchText) || String(translationText || "").toLowerCase().includes(searchText)
            property bool matchFilter: root.currentFilter === "ALL" ||
                                       (root.currentFilter === "PENDING" && (normalizedStatus === "PENDING" || normalizedStatus === "")) ||
                                       (root.currentFilter === "TRANSLATED" && (normalizedStatus === "TRANSLATED" || normalizedStatus === "EDITED")) ||
                                       (root.currentFilter === "ACCEPTED" && normalizedStatus === "ACCEPTED")
            property bool isSelected: ListView.isCurrentItem
            visible: matchSearch && matchFilter
            height: visible ? 64 : 0
            color: isSelected ? Theme.bgSurfaceElevated : (mouseArea.containsMouse ? Theme.bgSurfaceSoft : "transparent")

            Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 3; color: isSelected ? Theme.accentCyan : "transparent" }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.4; visible: delegateItem.visible }

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spaceMedium
                anchors.rightMargin: Theme.spaceMedium
                anchors.topMargin: Theme.spaceSmall
                anchors.bottomMargin: Theme.spaceSmall
                spacing: Theme.spaceXs
                visible: delegateItem.visible

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spaceSmall
                    Text { text: "#" + String(subIndex).padStart(3, '0'); color: Theme.textMuted; font.pixelSize: 12 }
                    Text { text: startTime; color: Theme.textMuted; font.pixelSize: 12 }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: normalizedStatus === "ACCEPTED" ? "✓ ACCEPTED" : normalizedStatus === "TRANSLATED" || normalizedStatus === "EDITED" ? "● TRANSLATED" : normalizedStatus === "TRANSLATING" ? "◌ TRANSLATING" : normalizedStatus === "ERROR" ? "✕ ERROR" : "○ PENDING"
                        color: normalizedStatus === "ACCEPTED" ? Theme.success : normalizedStatus === "TRANSLATED" || normalizedStatus === "EDITED" ? Theme.accentPurple : normalizedStatus === "ERROR" ? Theme.danger : Theme.textMuted
                        font.pixelSize: 10
                        font.bold: true
                    }
                }

                Text {
                    text: normalizedStatus === "ACCEPTED" ? translationText : originalText
                    color: isSelected ? Theme.textPrimary : Theme.textSecondary
                    font.pixelSize: 14
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            MouseArea { id: mouseArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: subListView.currentIndex = index }
        }

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; width: 8 }
    }

    Text {
        anchors.centerIn: subListView
        text: "📁 Mở file SRT hoặc Project\nđể bắt đầu làm việc."
        color: Theme.textDisabled
        font.pixelSize: 14
        horizontalAlignment: Text.AlignHCenter
        lineHeight: 1.5
        visible: subListView.count === 0
    }
}
