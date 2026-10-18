import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
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
    property bool showAdvancedFilters: false
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
        implicitHeight: headerControlsColumn.implicitHeight + (Theme.spaceSmall * 2)
        color: "transparent"
        border.width: 0

        ColumnLayout {
            id: headerControlsColumn
            anchors.fill: parent
            anchors.margins: Theme.spaceSmall
            spacing: Theme.spaceXs

            // TITLE ROW: DANH SÁCH CÂU + HOLD & DRAG BADGE (MATCHING DESIGN)
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "📋 DANH SÁCH CÂU"
                    font.pixelSize: 12
                    font.bold: true
                    color: "#FFFFFF"
                }

                Item { Layout.fillWidth: true }

                // Total count pill
                Rectangle {
                    implicitWidth: countBadgeText.implicitWidth + 14
                    implicitHeight: 20
                    radius: 10
                    color: Theme.badgeEmeraldBg
                    border.color: Theme.badgeEmeraldText
                    border.width: 1
                    Text {
                        id: countBadgeText
                        anchors.centerIn: parent
                        text: (subListView.count > 0 ? subListView.count : (typeof subtitleModel !== "undefined" && subtitleModel ? subtitleModel.rowCount() : 0)) + " câu"
                        color: Theme.badgeEmeraldText
                        font.pixelSize: 10
                        font.bold: true
                    }
                }

                // Filter expand toggle icon button
                Rectangle {
                    objectName: "btnToggleFilters"
                    implicitWidth: 26
                    implicitHeight: 20
                    radius: 10
                    color: root.showAdvancedFilters ? Theme.accentSapphire : Qt.rgba(1.0, 1.0, 1.0, 0.22)
                    border.color: Qt.rgba(1.0, 1.0, 1.0, 0.5)
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "⚙"
                        font.pixelSize: 11
                        color: "#FFFFFF"
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showAdvancedFilters = !root.showAdvancedFilters
                    }
                }
            }

            // Search Row - 100% FULL WIDTH SPACIOUS FROSTED GLASS TUBE
            RowLayout {
                id: searchLayout
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: Theme.spaceSmall

                TextField {
                    objectName: "searchInput"
                    id: searchInput
                    Layout.fillWidth: true
                    placeholderText: "🔍 Tìm kiếm nhanh..."
                    placeholderTextColor: "#64748B"
                    font.pixelSize: 12
                    color: "#0F172A"
                    background: Rectangle {
                        color: Qt.rgba(1.0, 1.0, 1.0, 0.88)
                        radius: 16
                        border.color: searchInput.activeFocus ? Theme.accentSapphire : Qt.rgba(1.0, 1.0, 1.0, 0.95)
                        border.width: searchInput.activeFocus ? 1.5 : 1
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
            }

            // ADVANCED FILTERS (COLLAPSED BY DEFAULT TO KEEP MINIMAL CLEAN UI)
            ColumnLayout {
                id: advancedFiltersContainer
                Layout.fillWidth: true
                visible: root.showAdvancedFilters
                spacing: 6

                // Filter Combo
                ComboBox {
                    objectName: "statusFilterCombo"
                    id: filterCombo
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
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
                        font.bold: true
                        color: "#0F172A"
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    indicator: Text {
                        x: filterCombo.width - width - Theme.spaceSmall
                        anchors.verticalCenter: parent.verticalCenter
                        text: statusPopup.visible ? "▴" : "▾"
                        color: Theme.accentSapphire
                        font.pixelSize: 12
                        font.bold: true
                    }

                    background: Rectangle {
                        implicitHeight: 32
                        color: Qt.rgba(1.0, 1.0, 1.0, 0.85)
                        radius: 12
                        border.color: filterCombo.activeFocus || statusPopup.visible ? Theme.accentSapphire : Qt.rgba(1.0, 1.0, 1.0, 0.90)
                        border.width: 1
                    }
                    
                    delegate: ItemDelegate {
                        width: filterCombo.width - 12
                        implicitHeight: 34
                        contentItem: RowLayout {
                            spacing: 8
                            Text {
                                text: modelData
                                color: "#0F172A"
                                font.pixelSize: 12
                                font.bold: highlighted || filterCombo.currentIndex === index
                                verticalAlignment: Text.AlignVCenter
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Text {
                                text: "✓"
                                color: Theme.accentSapphire
                                font.pixelSize: 12
                                font.bold: true
                                visible: filterCombo.currentIndex === index
                                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            }
                        }
                        background: Rectangle {
                            radius: 8
                            color: filterCombo.currentIndex === index ? Qt.rgba(0.0, 0.4, 1.0, 0.12) :
                                   highlighted ? Qt.rgba(0.0, 0.4, 1.0, 0.06) : "transparent"
                            border.color: filterCombo.currentIndex === index ? Qt.rgba(0.0, 0.4, 1.0, 0.35) : "transparent"
                            border.width: 1
                        }
                    }

                    popup: Popup {
                        id: statusPopup
                        y: filterCombo.height + 4
                        width: filterCombo.width
                        padding: 6
                        implicitHeight: Math.min(contentItem.implicitHeight + padding * 2, 260)

                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: statusPopup.visible ? filterCombo.delegateModel : null
                            currentIndex: filterCombo.highlightedIndex
                            ScrollIndicator.vertical: ScrollIndicator { }
                        }

                        background: Rectangle {
                            color: Qt.rgba(1.0, 1.0, 1.0, 0.96)
                            border.color: Qt.rgba(1.0, 1.0, 1.0, 0.98)
                            border.width: 1.5
                            radius: 14
                        }
                    }
                } // filterCombo

            // Chunk Filter Combo
            ComboBox {
                objectName: "chunkFilterCombo"
                id: chunkFilterCombo
                Layout.fillWidth: true
                Layout.minimumWidth: 0
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
                    font.bold: true
                    color: "#0F172A"
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                indicator: Text {
                    x: chunkFilterCombo.width - width - Theme.spaceSmall
                    anchors.verticalCenter: parent.verticalCenter
                    text: chunkPopup.visible ? "▴" : "▾"
                    color: Theme.accentSapphire
                    font.pixelSize: 12
                    font.bold: true
                }

                background: Rectangle {
                    implicitHeight: 32
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.85)
                    radius: 12
                    border.color: chunkFilterCombo.activeFocus || chunkPopup.visible ? Theme.accentSapphire : Qt.rgba(1.0, 1.0, 1.0, 0.90)
                    border.width: 1
                }

                delegate: ItemDelegate {
                    width: chunkFilterCombo.width - 12
                    implicitHeight: 34
                    contentItem: RowLayout {
                        spacing: 8
                        Text {
                            text: modelData
                            color: "#0F172A"
                            font.pixelSize: 12
                            font.bold: highlighted || chunkFilterCombo.currentIndex === index
                            verticalAlignment: Text.AlignVCenter
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        Text {
                            text: "✓"
                            color: Theme.accentSapphire
                            font.pixelSize: 12
                            font.bold: true
                            visible: chunkFilterCombo.currentIndex === index
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        }
                    }
                    background: Rectangle {
                        radius: 8
                        color: chunkFilterCombo.currentIndex === index ? Qt.rgba(0.0, 0.4, 1.0, 0.12) :
                               highlighted ? Qt.rgba(0.0, 0.4, 1.0, 0.06) : "transparent"
                        border.color: chunkFilterCombo.currentIndex === index ? Qt.rgba(0.0, 0.4, 1.0, 0.35) : "transparent"
                        border.width: 1
                    }
                }

                popup: Popup {
                    id: chunkPopup
                    y: chunkFilterCombo.height + 4
                    width: chunkFilterCombo.width
                    padding: 6
                    implicitHeight: Math.min(contentItem.implicitHeight + padding * 2, 260)

                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: chunkPopup.visible ? chunkFilterCombo.delegateModel : null
                        currentIndex: chunkFilterCombo.highlightedIndex
                        ScrollIndicator.vertical: ScrollIndicator { }
                    }

                    background: Rectangle {
                        color: Qt.rgba(1.0, 1.0, 1.0, 0.96)
                        border.color: Qt.rgba(1.0, 1.0, 1.0, 0.98)
                        border.width: 1.5
                        radius: 14
                    }
                }
            }


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
                        radius: 5
                        color: timeFilterCheck.checked ? Theme.accentSapphire : Qt.rgba(1.0, 1.0, 1.0, 0.85)
                        border.color: timeFilterCheck.checked ? Theme.accentSapphire : Qt.rgba(1.0, 1.0, 1.0, 0.95)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "✓"
                            color: "#FFFFFF"
                            font.pixelSize: 10
                            font.bold: true
                            visible: timeFilterCheck.checked
                        }
                    }
                    contentItem: Text {
                        text: timeFilterCheck.text
                        font.pixelSize: 11
                        font.bold: true
                        color: "#FFFFFF"
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: timeFilterCheck.indicator.width + Theme.spaceXs
                    }
                }

                TextField {
                    objectName: "startMinInput"
                    id: startMinInput
                    placeholderText: "Từ"
                    placeholderTextColor: "#64748B"
                    Layout.preferredWidth: 46
                    Layout.minimumWidth: 35
                    Layout.preferredHeight: 28
                    font.pixelSize: 12
                    font.bold: true
                    color: "#0F172A"
                    enabled: timeFilterCheck.checked
                    validator: IntValidator { bottom: 0; top: 9999 }
                    inputMethodHints: Qt.ImhDigitsOnly
                    onTextChanged: {
                        root.filterStartMin = isNaN(parseInt(text, 10)) ? 0 : parseInt(text, 10)
                        root.applyTimeFilter()
                    }
                    background: Rectangle {
                        color: Qt.rgba(1.0, 1.0, 1.0, 0.85)
                        radius: 8
                        border.color: startMinInput.activeFocus ? Theme.accentSapphire : Qt.rgba(1.0, 1.0, 1.0, 0.90)
                        border.width: 1
                    }
                }

                Text {
                    text: "➔"
                    color: "#FFFFFF"
                    font.pixelSize: 11
                    font.bold: true
                    Layout.alignment: Qt.AlignVCenter
                }

                TextField {
                    objectName: "endMinInput"
                    id: endMinInput
                    placeholderText: "Đến"
                    placeholderTextColor: "#64748B"
                    Layout.preferredWidth: 46
                    Layout.minimumWidth: 35
                    Layout.preferredHeight: 28
                    font.pixelSize: 12
                    font.bold: true
                    color: "#0F172A"
                    enabled: timeFilterCheck.checked
                    validator: IntValidator { bottom: 0; top: 9999 }
                    inputMethodHints: Qt.ImhDigitsOnly
                    onTextChanged: {
                        root.filterEndMin = isNaN(parseInt(text, 10)) ? 9999 : parseInt(text, 10)
                        root.applyTimeFilter()
                    }
                    background: Rectangle {
                        color: Qt.rgba(1.0, 1.0, 1.0, 0.85)
                        radius: 8
                        border.color: endMinInput.activeFocus ? Theme.accentSapphire : Qt.rgba(1.0, 1.0, 1.0, 0.90)
                        border.width: 1
                    }
                }

                Item { Layout.fillWidth: true }
            }
        } // advancedFiltersContainer
    } // headerControlsColumn
    } // header controls Rectangle

    // List View
    ListView {
        objectName: "subtitleList"
        id: subListView
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.bottomMargin: 8
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
            property bool isSelected: (root.selectedIndices && root.selectedIndices.indexOf(itemRawIndex) !== -1) ||
                                      ((!root.selectedIndices || root.selectedIndices.length <= 1) && subListView.currentIndex === index)
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

            property bool isCardDragging: false
            property real dragOffsetY: 0

            visible: root.isProxyModel ? true : (matchSearch && matchFilter && matchChunk && matchTime)
            height: visible ? 84 : 0
            color: "transparent"

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.topMargin: 3
                anchors.bottomMargin: 3
                hoverEnabled: true
                cursorShape: delegateItem.isCardDragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton
                z: 20

                property real startPressY: 0

                onPressed: function(mouse) {
                    startPressY = mouse.y
                    delegateItem.dragOffsetY = 0
                }

                onPositionChanged: function(mouse) {
                    if (pressed) {
                        var dy = mouse.y - startPressY
                        if (!delegateItem.isCardDragging && Math.abs(dy) > 8) {
                            delegateItem.isCardDragging = true
                        }
                        if (delegateItem.isCardDragging) {
                            delegateItem.dragOffsetY = dy
                        }
                    }
                }

                onReleased: function(mouse) {
                    if (delegateItem.isCardDragging) {
                        delegateItem.isCardDragging = false
                        var stepShift = Math.round(delegateItem.dragOffsetY / 84)
                        var targetIndex = Math.max(0, Math.min(subListView.count - 1, index + stepShift))

                        snapAnimation.to = 0
                        snapAnimation.start()

                        if (targetIndex !== subListView.currentIndex) {
                            subListView.currentIndex = targetIndex
                            var rIdx = root.isProxyModel ? subListView.model.getRawIndex(targetIndex) : targetIndex
                            root.selectedIndices = [rIdx]
                            root.selectionChanged(root.selectedIndices)
                        }
                    }
                }

                onClicked: function(mouse) {
                    if (delegateItem.isCardDragging) return
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

            // FLOATING LIQUID GLASS POD (WITH HOLD & DRAG D:\dichuyen.mp4)
            Rectangle {
                id: cardPod
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.topMargin: 4
                anchors.bottomMargin: 4
                radius: 16
                clip: true
                z: isSelected ? 5 : (delegateItem.isCardDragging ? 10 : 1)

                transform: Translate {
                    y: delegateItem.dragOffsetY
                }

                // Đổ bóng nổi khối 3D cho từng thẻ phụ đề
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: isSelected ? Qt.rgba(0.0, 0.38, 1.0, 0.42) : Qt.rgba(0.08, 0.04, 0.20, 0.14)
                    shadowBlur: isSelected ? 0.55 : 0.35
                    shadowVerticalOffset: isSelected ? 4 : 2
                }

                // Chuyển sang Gradient kính lỏng khi được chọn
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: isSelected ? "#0066FF" : (mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.88) : Theme.glassPodLuminous)
                    }
                    GradientStop {
                        position: 1.0
                        color: isSelected ? "#0284C7" : (mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.82) : Theme.glassPodLuminous)
                    }
                }

                border.color: isSelected ? "#7DD3FC" : Theme.glassBorderSpecularUpper
                border.width: isSelected ? 1.5 : 1

                // Vệt hắt sáng Specular 1px ở cạnh trên thẻ
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 1
                    height: 1
                    radius: parent.radius
                    color: Qt.rgba(1, 1, 1, isSelected ? 0.55 : 0.85)
                }

                scale: delegateItem.isCardDragging ? 0.96 : (mouseArea.pressed ? 0.98 : (mouseArea.containsMouse ? 1.01 : 1.0))
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                NumberAnimation {
                    id: snapAnimation
                    target: delegateItem
                    property: "dragOffsetY"
                    duration: 250
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.25
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.topMargin: 8
                    anchors.bottomMargin: 8
                    spacing: 4

                    // ROW 1: Index + Timecode + Duration + Status Badge
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        
                        Text {
                            text: "#" + String(subIndex).padStart(3, '0') + " • " + startTime
                            color: isSelected ? "#FFFFFF" : "#0369A1"
                            font.pixelSize: 11
                            font.bold: true
                        }

                        Text {
                            text: durationStr !== "" ? "(" + durationStr + ")" : ""
                            color: isSelected ? Qt.rgba(0.88, 0.95, 1.0, 0.75) : Theme.textOnLightPodMuted
                            font.pixelSize: 10
                        }
                        
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
                            implicitWidth: statusText.implicitWidth + 14
                            implicitHeight: 18
                            radius: 9
                            color: isSelected ? "#FEF08A" :
                                   normalizedStatus === "ACCEPTED" ? Theme.badgeEmeraldBg :
                                   normalizedStatus === "TRANSLATED" || normalizedStatus === "EDITED" ? Theme.badgeEmeraldBg :
                                   normalizedStatus === "ERROR" ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.15) :
                                   normalizedStatus === "TRANSLATING" ? Qt.rgba(0, 0.4, 1.0, 0.15) : Theme.badgeAmberBg
                            border.color: isSelected ? "#FDE047" :
                                          normalizedStatus === "ACCEPTED" || normalizedStatus === "TRANSLATED" || normalizedStatus === "EDITED" ? Theme.badgeEmeraldText :
                                          normalizedStatus === "ERROR" ? Theme.danger :
                                          normalizedStatus === "TRANSLATING" ? Theme.accentSapphire : Theme.badgeAmberText
                            border.width: 1
                            
                            Text {
                                id: statusText
                                anchors.centerIn: parent
                                text: isSelected ? "⭐ ĐANG XEM" :
                                      normalizedStatus === "ACCEPTED" ? "✓ ĐÃ DUYỆT" : 
                                      normalizedStatus === "TRANSLATED" || normalizedStatus === "EDITED" ? "✓ ĐÃ DỊCH" : 
                                      normalizedStatus === "TRANSLATING" ? "⚡ ĐANG DỊCH" : 
                                      normalizedStatus === "ERROR" ? "🛑 LỖI" : "⏳ CHỜ DUYỆT"
                                color: isSelected ? "#854D0E" :
                                       normalizedStatus === "ACCEPTED" || normalizedStatus === "TRANSLATED" || normalizedStatus === "EDITED" ? Theme.badgeEmeraldText :
                                       normalizedStatus === "ERROR" ? Theme.danger :
                                       normalizedStatus === "TRANSLATING" ? Theme.accentSapphire : Theme.badgeAmberText
                                font.pixelSize: 9
                                font.bold: true
                            }
                        }
                    }

                    // ROW 2: Subtitle text (Obsidian black on unselected, pure white on selected)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            Layout.fillWidth: true
                            text: originalText
                            color: isSelected ? "#FFFFFF" : Theme.textOnLightPod
                            font.pixelSize: 13
                            font.bold: true
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            wrapMode: Text.Wrap
                        }
                    }
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
        color: Qt.rgba(1.0, 1.0, 1.0, 0.16)
        border.color: Theme.glassBorderSubtle
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
                color: "#FFFFFF"
                font.pixelSize: 12
                font.bold: true
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
        visible: false
        Layout.fillWidth: true
        height: 24
        color: Qt.rgba(1.0, 1.0, 1.0, 0.12)
        border.color: Theme.glassBorderSubtle
        border.width: 1
        Text {
            anchors.centerIn: parent
            text: root.isProxyModel ? (subListView.model ? (subListView.model.filteredCount + " / " + subListView.model.totalCount + " câu") : "0 câu")
                                   : (root.filteredCount + " / " + subListView.count + " câu")
            color: Qt.rgba(1.0, 1.0, 1.0, 0.88)
            font.pixelSize: 11
        }
    }
}
