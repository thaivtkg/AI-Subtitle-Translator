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
    property string currentFilter: "ALL" // "ALL", "PENDING", "TRANSLATING", "TRANSLATED", "EDITED", "ERROR", "ACCEPTED"
    property string searchQuery: ""
    property int filteredCount: subListView.count
    property var selectedIndices: []

    property int currentChunkSize: 0 // 0 = Tất cả câu
    property int currentPage: 1
    property int selectedChunkStart: -1
    property int selectedChunkEnd: -1

    function updatePagination() {
        if (currentChunkSize <= 0 || subListView.count === 0) {
            selectedChunkStart = -1
            selectedChunkEnd = -1
        } else {
            var maxPage = Math.max(1, Math.ceil(subListView.count / currentChunkSize))
            if (currentPage > maxPage) currentPage = maxPage
            if (currentPage < 1) currentPage = 1
            selectedChunkStart = (currentPage - 1) * currentChunkSize
            selectedChunkEnd = Math.min(currentPage * currentChunkSize - 1, subListView.count - 1)
        }
        subListView.updateFilteredCount()
    }

    // Header controls
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: searchLayout.implicitHeight + (Theme.spaceSmall * 2)
        color: Theme.bgApp
        border.color: Theme.border
        border.width: 1

        RowLayout {
            id: searchLayout
            anchors.fill: parent
            anchors.margins: Theme.spaceSmall
            spacing: Theme.spaceSmall
            Layout.fillWidth: true
            Layout.minimumWidth: 0

            // Search
            TextField {
                objectName: "searchInput"
                id: searchInput
                Layout.fillWidth: true
                Layout.minimumWidth: 50
                placeholderText: "Tìm kiếm..."
                font.pixelSize: 12
                color: Theme.textPrimary
                background: Rectangle {
                    color: Theme.bgSurface
                    radius: Theme.radius
                    border.color: searchInput.activeFocus ? Theme.accentCyan : Theme.border
                }
                onTextChanged: root.searchQuery = text.toLowerCase()
            }

            // Chunk Filter Combo
            ComboBox {
                objectName: "chunkFilterCombo"
                id: chunkFilterCombo
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.preferredWidth: 105
                Layout.preferredHeight: 32
                font.pixelSize: 12
                model: [
                    "Tất cả câu",
                    "Hiển thị 5 câu / trang",
                    "Hiển thị 10 câu / trang",
                    "Hiển thị 20 câu / trang",
                    "Hiển thị 50 câu / trang"
                ]
                onCurrentIndexChanged: {
                    if (currentIndex === 0) root.currentChunkSize = 0
                    else if (currentIndex === 1) root.currentChunkSize = 5
                    else if (currentIndex === 2) root.currentChunkSize = 10
                    else if (currentIndex === 3) root.currentChunkSize = 20
                    else if (currentIndex === 4) root.currentChunkSize = 50
                    root.currentPage = 1
                    root.updatePagination()
                }

                contentItem: Text {
                    leftPadding: Theme.spaceSmall
                    rightPadding: chunkFilterCombo.indicator.width + Theme.spaceSmall
                    text: chunkFilterCombo.currentText
                    font.pixelSize: 12
                    color: Theme.textPrimary
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                indicator: Text {
                    x: chunkFilterCombo.width - width - Theme.spaceSmall
                    anchors.verticalCenter: parent.verticalCenter
                    text: chunkPopup.visible ? "▴" : "▾"
                    color: Theme.textSecondary
                    font.pixelSize: 12
                }

                background: Rectangle {
                    implicitWidth: 105
                    implicitHeight: 32
                    color: Theme.bgSurface
                    radius: Theme.radius
                    border.color: chunkFilterCombo.activeFocus || chunkPopup.visible ? Theme.accentCyan : Theme.border
                    border.width: 1
                }

                delegate: ItemDelegate {
                    width: chunkFilterCombo.width - (Theme.spaceXs * 2)
                    contentItem: Text {
                        text: modelData
                        color: highlighted ? Theme.accentCyan : Theme.textPrimary
                        font.pixelSize: 12
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: highlighted ? Theme.bgSurfaceElevated : (chunkFilterCombo.currentIndex === index ? Theme.bgSurfaceSoft : "transparent")
                        radius: 4
                    }
                }

                popup: Popup {
                    id: chunkPopup
                    y: chunkFilterCombo.height + 4
                    width: chunkFilterCombo.width
                    padding: Theme.spaceXs
                    implicitHeight: Math.min(contentItem.implicitHeight + padding * 2, 220)

                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: chunkPopup.visible ? chunkFilterCombo.delegateModel : null
                        currentIndex: chunkFilterCombo.highlightedIndex
                        ScrollIndicator.vertical: ScrollIndicator { }
                    }

                    background: Rectangle {
                        color: Theme.bgSurface
                        border.color: Theme.border
                        border.width: 1
                        radius: Theme.radius
                    }
                }
            }

            // Filter Combo
            ComboBox {
                objectName: "statusFilterCombo"
                id: filterCombo
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.preferredWidth: 105
                Layout.preferredHeight: 32
                font.pixelSize: 12
                model: ["Tất cả", "Chờ dịch", "Đang dịch", "Đã dịch", "Đã sửa", "Lỗi", "Đã duyệt"]
                onCurrentIndexChanged: {
                    const filters = ["ALL", "PENDING", "TRANSLATING", "TRANSLATED", "EDITED", "ERROR", "ACCEPTED"]
                    root.currentFilter = filters[currentIndex]
                }

                contentItem: Text {
                    leftPadding: Theme.spaceSmall
                    rightPadding: filterCombo.indicator.width + Theme.spaceSmall
                    text: filterCombo.currentText
                    font.pixelSize: 12
                    color: Theme.textPrimary
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                indicator: Text {
                    x: filterCombo.width - width - Theme.spaceSmall
                    anchors.verticalCenter: parent.verticalCenter
                    text: statusPopup.visible ? "▴" : "▾"
                    color: Theme.textSecondary
                    font.pixelSize: 12
                }

                background: Rectangle {
                    implicitWidth: 120
                    implicitHeight: 32
                    color: Theme.bgSurface
                    radius: Theme.radius
                    border.color: filterCombo.activeFocus || statusPopup.visible ? Theme.accentCyan : Theme.border
                    border.width: 1
                }
                
                delegate: ItemDelegate {
                    width: filterCombo.width - (Theme.spaceXs * 2)
                    contentItem: Text {
                        text: modelData
                        color: highlighted ? Theme.accentCyan : Theme.textPrimary
                        font.pixelSize: 12
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: highlighted ? Theme.bgSurfaceElevated : (filterCombo.currentIndex === index ? Theme.bgSurfaceSoft : "transparent")
                        radius: 4
                    }
                }

                popup: Popup {
                    id: statusPopup
                    y: filterCombo.height + 4
                    width: filterCombo.width
                    padding: Theme.spaceXs
                    implicitHeight: Math.min(contentItem.implicitHeight + padding * 2, 220)

                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: statusPopup.visible ? filterCombo.delegateModel : null
                        currentIndex: filterCombo.highlightedIndex
                        ScrollIndicator.vertical: ScrollIndicator { }
                    }

                    background: Rectangle {
                        color: Theme.bgSurface
                        border.color: Theme.border
                        border.width: 1
                        radius: Theme.radius
                    }
                }
            }
        }
    }

    // List View
    ListView {
        objectName: "subtitleList"
        id: subListView
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: typeof subtitleModel !== "undefined" ? subtitleModel : null
        currentIndex: -1
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { active: true }

        onContentHeightChanged: updateFilteredCount()
        Component.onCompleted: {
            if (count > 0) translationController.loadSubtitle(0)
            updateFilteredCount()
        }
        onCountChanged: {
            if (count > 0 && currentIndex < 0) {
                currentIndex = 0
            }
            if (count === 0) {
                root.selectedIndices = []
            }
            root.updatePagination()
        }
        onCurrentIndexChanged: { if (currentIndex >= 0) translationController.loadSubtitle(currentIndex) }

        function updateFilteredCount() { filteredCount = Math.round(contentHeight / 64) }

        delegate: Rectangle {
            objectName: "subtitleRow_" + index
            id: delegateItem
            width: subListView.width
            property string normalizedStatus: typeof status !== "undefined" ? (status === "Translating" ? "TRANSLATING" : status) : "PENDING"
            property bool matchSearch: root.searchQuery === "" ||
                                       (typeof originalText !== "undefined" && originalText.toLowerCase().indexOf(root.searchQuery) !== -1) ||
                                       (typeof translationText !== "undefined" && translationText.toLowerCase().indexOf(root.searchQuery) !== -1)
            property bool matchFilter: root.currentFilter === "ALL" ||
                                       (root.currentFilter === "PENDING" && (normalizedStatus === "PENDING" || normalizedStatus === "")) ||
                                       normalizedStatus === root.currentFilter
            property bool matchChunk: root.selectedChunkStart < 0 || (index >= root.selectedChunkStart && index <= root.selectedChunkEnd)
            property bool isSelected: (root.selectedIndices.indexOf(index) !== -1) || (root.selectedIndices.length <= 1 && ListView.isCurrentItem)
            property bool hasTranslation: typeof translationText !== "undefined" && String(translationText).trim().length > 0
            
            property string durationStr: {
                if (!startTime || !endTime) return ""
                function toSec(t) {
                    var p = t.replace(',', ':').split(':')
                    if (p.length < 4) return 0
                    return parseInt(p[0])*3600 + parseInt(p[1])*60 + parseInt(p[2]) + parseInt(p[3])/1000
                }
                var d = toSec(endTime) - toSec(startTime)
                return d > 0 ? d.toFixed(1) + "s" : ""
            }

            visible: matchSearch && matchFilter && matchChunk
            height: visible ? (hasTranslation ? 82 : 62) : 0
            
            color: isSelected ? Theme.bgSurfaceElevated : (mouseArea.containsMouse ? Theme.bgSurfaceSoft : "transparent")
            border.color: isSelected ? Theme.accentCyan : "transparent"
            border.width: isSelected ? 1 : 0
            radius: isSelected ? 4 : 0

            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: isSelected ? 0 : 0.4; visible: delegateItem.visible }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton
                onClicked: function(mouse) {
                    if (mouse.modifiers & Qt.ControlModifier) {
                        var list = root.selectedIndices.slice()
                        var pos = list.indexOf(index)
                        if (pos !== -1) {
                            list.splice(pos, 1)
                        } else {
                            list.push(index)
                        }
                        root.selectedIndices = list
                    } else {
                        root.selectedIndices = [index]
                    }
                    subListView.currentIndex = index
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spaceMedium
                anchors.rightMargin: Theme.spaceMedium
                anchors.topMargin: Theme.spaceSmall
                anchors.bottomMargin: Theme.spaceSmall
                spacing: 2
                visible: delegateItem.visible

                // ROW 1
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spaceSmall
                    
                    Rectangle {
                        implicitWidth: 32
                        implicitHeight: 18
                        radius: 4
                        color: isSelected ? Theme.accentCyan : Theme.bgSurfaceSoft
                        Text {
                            anchors.centerIn: parent
                            text: "#" + String(subIndex).padStart(3, '0')
                            color: isSelected ? Theme.bgApp : Theme.textMuted
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }
                    
                    Text { text: startTime; color: Theme.textMuted; font.pixelSize: 12 }
                    Text { text: "(" + durationStr + ")"; color: Theme.textDisabled; font.pixelSize: 11 }
                    
                    Item { Layout.fillWidth: true }
                    
                    Text {
                        z: 2
                        visible: typeof qaSeverity !== "undefined" && qaSeverity !== ""
                        text: qaSeverity === "ERROR" ? "🛑" : "⚠️"
                        font.pixelSize: 11
                        ToolTip.visible: qaHoverArea.containsMouse
                        ToolTip.text: typeof qaTooltip !== "undefined" ? qaTooltip : ""
                        ToolTip.delay: 200
                        MouseArea {
                            id: qaHoverArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: subListView.currentIndex = index
                        }
                    }
                    
                    Rectangle {
                        implicitWidth: statusText.implicitWidth + 12
                        implicitHeight: 18
                        radius: 9
                        color: normalizedStatus === "ACCEPTED" ? Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.15) :
                               normalizedStatus === "ERROR" ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.15) :
                               normalizedStatus === "TRANSLATED" || normalizedStatus === "EDITED" ? Qt.rgba(Theme.accentPurple.r, Theme.accentPurple.g, Theme.accentPurple.b, 0.15) :
                               normalizedStatus === "TRANSLATING" ? Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.15) :
                               Theme.bgSurfaceSoft
                        
                        Text {
                            id: statusText
                            anchors.centerIn: parent
                            text: normalizedStatus === "ACCEPTED" ? "✓ ACCEPTED" : 
                                  normalizedStatus === "TRANSLATED" || normalizedStatus === "EDITED" ? "★ TRANSLATED" : 
                                  normalizedStatus === "TRANSLATING" ? "⚡ TRANSLATING" : 
                                  normalizedStatus === "ERROR" ? "🛑 ERROR" : "○ PENDING"
                            color: normalizedStatus === "ACCEPTED" ? Theme.success : 
                                   normalizedStatus === "TRANSLATED" || normalizedStatus === "EDITED" ? Theme.accentPurple : 
                                   normalizedStatus === "ERROR" ? Theme.danger : 
                                   normalizedStatus === "TRANSLATING" ? Theme.accentCyan : Theme.textMuted
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }
                }

                // ROW 2: Original Text
                Text {
                    Layout.fillWidth: true
                    text: originalText
                    color: Theme.textPrimary
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
                
                // ROW 3: Translation Text (if exists)
                Text {
                    visible: hasTranslation
                    Layout.fillWidth: true
                    text: typeof translationText !== "undefined" ? translationText : ""
                    color: Theme.accentCyan
                    opacity: 0.8
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
        }
    }

    // Pagination bar
    Rectangle {
        objectName: "paginationBar"
        id: paginationBar
        Layout.fillWidth: true
        Layout.preferredHeight: 34
        visible: root.currentChunkSize > 0 && subListView.count > 0
        color: Theme.bgSurface
        border.color: Theme.border
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spaceSmall
            anchors.rightMargin: Theme.spaceSmall
            spacing: Theme.spaceSmall

            AppButton {
                objectName: "btnPrevPage"
                text: "◀"
                implicitWidth: 32
                implicitHeight: 26
                enabled: root.currentPage > 1
                onClicked: {
                    if (root.currentPage > 1) {
                        root.currentPage--
                        root.updatePagination()
                    }
                }
            }

            Text {
                objectName: "paginationText"
                text: "Trang " + root.currentPage + " / " + Math.max(1, Math.ceil(subListView.count / (root.currentChunkSize > 0 ? root.currentChunkSize : 1)))
                color: Theme.textPrimary
                font.pixelSize: 12
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            AppButton {
                objectName: "btnNextPage"
                text: "▶"
                implicitWidth: 32
                implicitHeight: 26
                enabled: root.currentPage < Math.ceil(subListView.count / (root.currentChunkSize > 0 ? root.currentChunkSize : 1))
                onClicked: {
                    if (root.currentPage < Math.ceil(subListView.count / (root.currentChunkSize > 0 ? root.currentChunkSize : 1))) {
                        root.currentPage++
                        root.updatePagination()
                    }
                }
            }
        }
    }

    // Footer stats
    Rectangle {
        Layout.fillWidth: true
        height: 24
        color: Theme.bgSurface
        border.color: Theme.border
        border.width: 1
        Text {
            anchors.centerIn: parent
            text: root.filteredCount + " / " + subListView.count + " câu"
            color: Theme.textMuted
            font.pixelSize: 11
        }
    }
}
