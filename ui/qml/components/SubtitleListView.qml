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
            Text { text: subListView.filteredCount + " / " + subListView.count + " items"; color: Theme.textMuted; font.pixelSize: 12 }
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: compProgress.visible ? compProgress.implicitHeight + Theme.spaceMedium : 0
        color: Theme.bgSurface
        visible: compProgress.visible
        clip: true
        CompletionProgress {
            id: compProgress
            anchors.fill: parent
            anchors.leftMargin: Theme.spaceMedium
            anchors.rightMargin: Theme.spaceMedium
            anchors.topMargin: Theme.spaceSmall
            anchors.bottomMargin: Theme.spaceSmall
            acceptedCount: translationController.acceptedCount
            totalCount: translationController.totalSubtitleCount
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
                objectName: "searchInput"
                id: searchInput
                Layout.fillWidth: true
                Layout.margins: Theme.spaceSmall
                Layout.bottomMargin: Theme.spaceXs
                placeholderText: activeFocus ? "Search text..." : "🔍 Search text..."
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

            ComboBox {
                objectName: "statusFilterCombo"
                id: statusFilterCombo
                Layout.fillWidth: true
                Layout.leftMargin: Theme.spaceSmall
                Layout.rightMargin: Theme.spaceSmall
                Layout.bottomMargin: Theme.spaceSmall
                model: ["ALL", "PENDING", "TRANSLATING", "TRANSLATED", "EDITED", "ACCEPTED", "ERROR"]
                contentItem: Text {
                    text: statusFilterCombo.currentText === "ALL" ? "All statuses" : statusFilterCombo.currentText
                    color: Theme.textPrimary
                    font.pixelSize: 14
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: Theme.spaceSmall
                }
                background: Rectangle {
                    color: Theme.bgApp
                    radius: Theme.radius
                    border.color: statusFilterCombo.activeFocus ? Theme.accentCyan : Theme.border
                    border.width: 1
                }
                onCurrentTextChanged: root.currentFilter = currentText

                delegate: ItemDelegate {
                    width: statusFilterCombo.width
                    contentItem: Text {
                        text: modelData
                        color: highlighted ? Theme.textPrimary : Theme.textSecondary
                        font.pixelSize: 14
                        font.bold: highlighted
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: highlighted ? Theme.bgSurfaceSoft : "transparent"
                        radius: 2
                    }
                    highlighted: statusFilterCombo.highlightedIndex === index
                }

                popup: Popup {
                    y: statusFilterCombo.height + 4
                    width: statusFilterCombo.width
                    padding: Theme.spaceXs
                    implicitHeight: Math.min(contentItem.implicitHeight + padding * 2, 240)

                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: statusFilterCombo.popup.visible ? statusFilterCombo.delegateModel : null
                        currentIndex: statusFilterCombo.highlightedIndex
                        ScrollIndicator.vertical: ScrollIndicator { }
                    }

                    background: Rectangle {
                        color: Theme.bgSurfaceElevated
                        border.color: Theme.border
                        border.width: 1
                        radius: Theme.radius
                    }
                }
            }
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
    }

    ListView {
        objectName: "subtitleList"
        id: subListView
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        property int filteredCount: 0

        onContentHeightChanged: updateFilteredCount()
        Component.onCompleted: {
            if (count > 0) translationController.loadSubtitle(0)
            updateFilteredCount()
        }
        onCurrentIndexChanged: { if (currentIndex >= 0) translationController.loadSubtitle(currentIndex) }

        function updateFilteredCount() { filteredCount = Math.round(contentHeight / 64) }

        delegate: Rectangle {
            objectName: "subtitleRow_" + index
            id: delegateItem
            width: subListView.width
            property string normalizedStatus: String(status || "PENDING").toUpperCase()
            property string searchText: searchInput.text.toLowerCase()
            property bool matchSearch: searchText === "" || String(originalText || "").toLowerCase().includes(searchText) || String(translationText || "").toLowerCase().includes(searchText)
            property bool matchFilter: root.currentFilter === "ALL" ||
                                       (root.currentFilter === "PENDING" && (normalizedStatus === "PENDING" || normalizedStatus === "")) ||
                                       normalizedStatus === root.currentFilter
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

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Theme.spaceMedium
            visible: subListView.count > 0 && subListView.filteredCount === 0 && (searchInput.text !== "" || root.currentFilter !== "ALL")

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "No subtitles found"
                color: Theme.textPrimary
                font.pixelSize: 18
                font.bold: true
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Try changing your search query or status filter."
                color: Theme.textMuted
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
            }
            AppButton {
                Layout.alignment: Qt.AlignHCenter
                text: "Clear filters"
                onClicked: {
                    searchInput.text = ""
                    statusFilterCombo.currentIndex = 0
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignCenter
        text: "📁 Mở file SRT hoặc Project\nđể bắt đầu làm việc."
        color: Theme.textDisabled
        font.pixelSize: 14
        horizontalAlignment: Text.AlignHCenter
        lineHeight: 1.5
        visible: subListView.count === 0
    }
}
