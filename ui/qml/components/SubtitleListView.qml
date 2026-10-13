import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

ColumnLayout {
    id: root
    objectName: "subtitleListView"
    spacing: 0

    property alias model: subListView.model
    property alias currentIndex: subListView.currentIndex
    property alias count: subListView.count
    property bool isProxyModel: subListView.model && typeof subListView.model.getRawIndex === "function"
    property int currentRawIndex: {
        if (currentIndex < 0 || currentIndex >= count) return -1
        if (isProxyModel) return subListView.model.getRawIndex(currentIndex)
        return currentIndex
    }
    property string currentFilter: "ALL" // "ALL", "PENDING", "TRANSLATING", "TRANSLATED", "EDITED", "ERROR", "ACCEPTED"
    property string searchQuery: ""
    property int clientFilteredCount: subListView.count
    property int filteredCount: isProxyModel ? (subListView.model ? subListView.model.filteredCount : 0) : clientFilteredCount
    property var selectedIndices: []
    signal selectionChanged(var indices)

    property int currentChunkSize: 0 // 0 = Tất cả câu
    property int currentPage: 1
    property int selectedChunkStart: -1
    property int selectedChunkEnd: -1

    property bool isTimeFilterActive: false
    property int filterStartMin: 0
    property int filterEndMin: 9999

    function updatePagination() {
        if (root.isProxyModel) return
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
        updateFiltersAndScroll()
    }

    function applyTimeFilter() {
        if (root.isProxyModel) {
            subListView.model.setTimeFilter(root.isTimeFilterActive, root.filterStartMin, root.filterEndMin)
        } else {
            root.updateFiltersAndScroll()
        }
        subListView.positionViewAtIndex(0, ListView.Beginning)
        subListView.contentY = 0
    }

    function updateFiltersAndScroll() {
        updateFilteredCount()
        subListView.positionViewAtIndex(0, ListView.Beginning)
        subListView.contentY = 0
    }

    function updateFilteredCount() {
        if (root.isProxyModel) return
        if (!subListView.model) {
            clientFilteredCount = 0
            return
        }
        if (!root.isTimeFilterActive && root.searchQuery === "" && root.currentFilter === "ALL" && root.currentChunkSize <= 0) {
            clientFilteredCount = subListView.count
            return
        }
        var all = (typeof subtitleModel !== "undefined" && subtitleModel) ? subtitleModel.get_all_data() : []
        if (!all || all.length === 0) {
            clientFilteredCount = 0
            return
        }
        var count = 0
        var sq = root.searchQuery
        var cf = root.currentFilter
        var tf = root.isTimeFilterActive
        var sMin = root.filterStartMin
        var eMin = root.filterEndMin
        var cSize = root.currentChunkSize
        var cStart = root.selectedChunkStart
        var cEnd = root.selectedChunkEnd

        for (var i = 0; i < all.length; i++) {
            var item = all[i]
            if (sq !== "") {
                var orig = (item.original || "").toLowerCase()
                var trans = (item.translation || "").toLowerCase()
                if (orig.indexOf(sq) === -1 && trans.indexOf(sq) === -1) continue
            }
            if (cf !== "ALL") {
                var st = (item.status || "PENDING").toUpperCase()
                if (cf === "PENDING" && st !== "PENDING" && st !== "") continue
                else if (cf !== "PENDING" && st !== cf) continue
            }
            if (tf) {
                var tStr = item.start_time || ""
                var subM = (parseInt(tStr.substring(0, 2), 10) || 0) * 60 + (parseInt(tStr.substring(3, 5), 10) || 0)
                if (subM < sMin || subM > eMin) continue
            }
            if (!tf && cSize > 0 && cStart >= 0) {
                if (i < cStart || i > cEnd) continue
            }
            count++
        }
        clientFilteredCount = count
    }

    // Header controls
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: headerControlsColumn.implicitHeight + (Theme.spaceSmall * 2)
        implicitHeight: Layout.preferredHeight
        color: Theme.bgApp
        border.color: Theme.border
        border.width: 1

        ColumnLayout {
            id: headerControlsColumn
            anchors.fill: parent
            anchors.margins: Theme.spaceSmall
            spacing: Theme.spaceXs

            RowLayout {
                id: searchLayout
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: Theme.spaceSmall

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
                onTextChanged: {
                    root.searchQuery = text.toLowerCase()
                    if (root.isProxyModel) {
                        subListView.model.setSearchQuery(text)
                    } else {
                        root.updateFiltersAndScroll()
                    }
                    subListView.positionViewAtIndex(0, ListView.Beginning)
                    subListView.contentY = 0
                }
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
                    var sizes = [0, 5, 10, 20, 50]
                    root.currentChunkSize = sizes[currentIndex]
                    root.currentPage = 1
                    if (root.isProxyModel) {
                        subListView.model.setPageSize(sizes[currentIndex])
                    } else {
                        root.updatePagination()
                    }
                    subListView.positionViewAtIndex(0, ListView.Beginning)
                    subListView.contentY = 0
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
                    if (root.isProxyModel) {
                        subListView.model.setStatusFilter(filters[currentIndex])
                    } else {
                        root.updateFiltersAndScroll()
                    }
                    subListView.positionViewAtIndex(0, ListView.Beginning)
                    subListView.contentY = 0
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
            } // filterCombo
        } // searchLayout

            // Time Filter Row
            RowLayout {
                id: timeFilterLayout
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: Theme.spaceXs

                CheckBox {
                    objectName: "timeFilterCheck"
                    id: timeFilterCheck
                    text: "Lọc phút:"
                    Layout.minimumWidth: 0
                    ToolTip.text: "Lọc hiển thị theo phút bắt đầu. Trình dịch AI sẽ chạy tuần tự từ câu đang chọn."
                    ToolTip.visible: hovered
                    onCheckedChanged: {
                        root.isTimeFilterActive = checked
                        root.applyTimeFilter()
                    }
                    indicator: Rectangle {
                        implicitWidth: 16
                        implicitHeight: 16
                        x: timeFilterCheck.leftPadding
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 3
                        color: timeFilterCheck.checked ? Theme.accentCyan : Theme.bgSurface
                        border.color: timeFilterCheck.checked ? Theme.accentCyan : Theme.border
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "✓"
                            color: Theme.bgApp
                            font.pixelSize: 10
                            font.bold: true
                            visible: timeFilterCheck.checked
                        }
                    }
                    contentItem: Text {
                        text: timeFilterCheck.text
                        font.pixelSize: 11
                        color: timeFilterCheck.checked ? Theme.accentCyan : Theme.textSecondary
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: timeFilterCheck.indicator.width + Theme.spaceXs
                    }
                }

                TextField {
                    objectName: "startMinInput"
                    id: startMinInput
                    placeholderText: "Từ"
                    Layout.preferredWidth: 46
                    Layout.minimumWidth: 35
                    Layout.preferredHeight: 28
                    font.pixelSize: 12
                    color: Theme.textPrimary
                    enabled: timeFilterCheck.checked
                    validator: IntValidator { bottom: 0; top: 9999 }
                    inputMethodHints: Qt.ImhDigitsOnly
                    onTextChanged: {
                        root.filterStartMin = isNaN(parseInt(text, 10)) ? 0 : parseInt(text, 10)
                        root.applyTimeFilter()
                    }
                    background: Rectangle {
                        color: Theme.bgSurface
                        radius: Theme.radius
                        border.color: startMinInput.activeFocus ? Theme.accentCyan : Theme.border
                        border.width: 1
                    }
                }

                Text {
                    text: "➔"
                    color: Theme.textSecondary
                    font.pixelSize: 11
                    Layout.alignment: Qt.AlignVCenter
                }

                TextField {
                    objectName: "endMinInput"
                    id: endMinInput
                    placeholderText: "Đến"
                    Layout.preferredWidth: 46
                    Layout.minimumWidth: 35
                    Layout.preferredHeight: 28
                    font.pixelSize: 12
                    color: Theme.textPrimary
                    enabled: timeFilterCheck.checked
                    validator: IntValidator { bottom: 0; top: 9999 }
                    inputMethodHints: Qt.ImhDigitsOnly
                    onTextChanged: {
                        root.filterEndMin = isNaN(parseInt(text, 10)) ? 9999 : parseInt(text, 10)
                        root.applyTimeFilter()
                    }
                    background: Rectangle {
                        color: Theme.bgSurface
                        radius: Theme.radius
                        border.color: endMinInput.activeFocus ? Theme.accentCyan : Theme.border
                        border.width: 1
                    }
                }

                Item { Layout.fillWidth: true }
            }
        } // headerControlsColumn
    }

    // List View
    ListView {
        objectName: "subtitleList"
        id: subListView
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: typeof filteredSubtitleModel !== "undefined" && filteredSubtitleModel ? filteredSubtitleModel : (typeof subtitleModel !== "undefined" ? subtitleModel : null)
        currentIndex: -1
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { active: true }

        Component.onCompleted: {
            if (count > 0) translationController.loadSubtitle(root.currentRawIndex >= 0 ? root.currentRawIndex : 0)
            root.updateFilteredCount()
        }
        onCountChanged: {
            if (count > 0 && currentIndex < 0) {
                currentIndex = 0
            }
            if (count === 0) {
                root.selectedIndices = []
                root.selectionChanged([])
            }
            if (!root.isProxyModel) {
                root.updatePagination()
            }
        }
        onCurrentIndexChanged: {
            var raw = (root.isProxyModel && subListView.model && typeof subListView.model.getRawIndex === "function")
                      ? subListView.model.getRawIndex(currentIndex)
                      : currentIndex
            if (raw >= 0) translationController.loadSubtitle(raw)
        }

        delegate: Rectangle {
            objectName: "subtitleRow_" + (typeof rawIndex !== "undefined" ? rawIndex : index)
            id: delegateItem
            width: subListView.width
            property int itemRawIndex: root.isProxyModel ? (typeof rawIndex !== "undefined" ? rawIndex : (subListView.model.getRawIndex ? subListView.model.getRawIndex(index) : index)) : index
            property string normalizedStatus: typeof status !== "undefined" ? (status === "Translating" ? "TRANSLATING" : status) : "PENDING"
            property bool matchSearch: root.isProxyModel ? true : (root.searchQuery === "" ||
                                       (typeof originalText !== "undefined" && originalText.toLowerCase().indexOf(root.searchQuery) !== -1) ||
                                       (typeof translationText !== "undefined" && translationText.toLowerCase().indexOf(root.searchQuery) !== -1))
            property bool matchFilter: root.isProxyModel ? true : (root.currentFilter === "ALL" ||
                                       (root.currentFilter === "PENDING" && (normalizedStatus === "PENDING" || normalizedStatus === "")) ||
                                       normalizedStatus === root.currentFilter)
            property int subStartMin: {
                if (!startTime || startTime.length < 5) return 0;
                return (parseInt(startTime.substring(0, 2), 10) || 0) * 60 + (parseInt(startTime.substring(3, 5), 10) || 0);
            }
            property bool matchTime: root.isProxyModel ? true : (!root.isTimeFilterActive ||
                                     (subStartMin >= root.filterStartMin && subStartMin <= root.filterEndMin))
            property bool matchChunk: root.isProxyModel ? true : (root.selectedChunkStart < 0 ||
                                      root.isTimeFilterActive ||
                                      (index >= root.selectedChunkStart && index <= root.selectedChunkEnd))
            property bool isSelected: (root.selectedIndices.indexOf(itemRawIndex) !== -1) || (root.selectedIndices.length <= 1 && ListView.isCurrentItem)
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

            visible: root.isProxyModel ? true : (matchSearch && matchFilter && matchChunk && matchTime)
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
                    var list = []
                    if (mouse.modifiers & Qt.ControlModifier) {
                        list = (root.selectedIndices && root.selectedIndices.length > 0) ? root.selectedIndices.slice() : (root.currentRawIndex >= 0 ? [root.currentRawIndex] : [])
                        var pos = list.indexOf(delegateItem.itemRawIndex)
                        if (pos !== -1) {
                            list.splice(pos, 1)
                        } else {
                            list.push(delegateItem.itemRawIndex)
                        }
                    } else if (mouse.modifiers & Qt.ShiftModifier) {
                        var start = (subListView.currentIndex >= 0) ? subListView.currentIndex : index
                        var minIdx = Math.min(start, index)
                        var maxIdx = Math.max(start, index)
                        for (var i = minIdx; i <= maxIdx; i++) {
                            var rIdx = root.isProxyModel ? subListView.model.getRawIndex(i) : i
                            list.push(rIdx)
                        }
                    } else {
                        list = [delegateItem.itemRawIndex]
                    }
                    root.selectedIndices = list
                    root.selectionChanged(list)
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
        visible: root.isProxyModel ? (subListView.model && subListView.model.pageSize > 0 && subListView.model.filteredCount > 0)
                                   : (root.currentChunkSize > 0 && subListView.count > 0 && !root.isTimeFilterActive)
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
                enabled: root.isProxyModel ? (subListView.model && subListView.model.hasPrevPage) : (root.currentPage > 1)
                onClicked: {
                    if (root.isProxyModel) {
                        subListView.model.prevPage()
                    } else if (root.currentPage > 1) {
                        root.currentPage--
                        root.updatePagination()
                    }
                    subListView.positionViewAtIndex(0, ListView.Beginning)
                    subListView.contentY = 0
                }
            }

            Text {
                objectName: "paginationText"
                text: root.isProxyModel
                      ? (subListView.model ? ("Trang " + subListView.model.currentPage + " / " + subListView.model.totalPages) : "")
                      : ("Trang " + root.currentPage + " / " + Math.max(1, Math.ceil(subListView.count / (root.currentChunkSize > 0 ? root.currentChunkSize : 1))))
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
                enabled: root.isProxyModel ? (subListView.model && subListView.model.hasNextPage) : (root.currentPage < Math.ceil(subListView.count / (root.currentChunkSize > 0 ? root.currentChunkSize : 1)))
                onClicked: {
                    if (root.isProxyModel) {
                        subListView.model.nextPage()
                    } else if (root.currentPage < Math.ceil(subListView.count / (root.currentChunkSize > 0 ? root.currentChunkSize : 1))) {
                        root.currentPage++
                        root.updatePagination()
                    }
                    subListView.positionViewAtIndex(0, ListView.Beginning)
                    subListView.contentY = 0
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
            text: root.isProxyModel ? (subListView.model ? (subListView.model.filteredCount + " / " + subListView.model.totalCount + " câu") : "0 câu")
                                   : (root.filteredCount + " / " + subListView.count + " câu")
            color: Theme.textMuted
            font.pixelSize: 11
        }
    }
}
