import QtQuick
import QtQuick.Controls

import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.kitemmodels as KItemModels

FocusScope {
    id: searchResults

    signal keyNavUp
    signal keyNavDown

    // Layout properties passed from MenuRepresentation
    property int numberColumns: 8
    property int referenceColumns: 8
    property int numberRows: 3
    property int referenceRows: 5
    
    property int iconSize: Kirigami.Units.iconSizes.large

    // Stabilize cell calculations by using root dimensions
    readonly property int cellSizeWidth: Math.floor(width / referenceColumns)
    readonly property int cellSizeHeight: Math.floor(height / referenceRows)

    property var model: null
    property string query: ""

    property var allResults: []
    
    readonly property int pageItemsCount: Math.max(1, numberColumns * numberRows)
    readonly property int pageTotalCount: Math.max(1, Math.ceil(allResults.length / pageItemsCount))

    readonly property var currentItemGrid: viewSwipeView.currentItem ? viewSwipeView.currentItem : null
    readonly property var currentMatch: (currentItemGrid && currentItemGrid.currentIndex !== -1) ? allResults[internalIndex(currentItemGrid.currentIndex)] : null

    function internalIndex(gridIndex) {
        return gridIndex + (viewSwipeView.currentIndex * pageItemsCount);
    }

    function selectFirst() {
        if (currentItemGrid) {
            currentItemGrid.currentIndex = 0;
        }
    }

    function triggerSelected() {
        if (currentMatch) {
            try {
                if (currentMatch.runnerModel && typeof currentMatch.runnerModel.trigger === "function") {
                    currentMatch.runnerModel.trigger(currentMatch.modelIndex, "", null);
                    root.toggle();
                }
            } catch (e) {
                console.error("Error triggering search result:", e);
            }
        }
    }

    function removeSelection() {
        if (currentItemGrid) {
            currentItemGrid.currentIndex = -1;
        }
    }

    // Satisfy ItemGridDelegate's expectation for directory model fetching
    function modelForRow(row) {
        return null;
    }

    function requestUpdate() {
        buildFlatResults()
    }

    // Build flat array from all runner results with tiered sorting
    function buildFlatResults() {
        if (!model) {
            allResults = []
            return
        }

        let highPriority = []
        let mediumPriority = []
        let lowerQuery = query.toLowerCase()

        for (let i = 0; i < model.count; i++) {
            let rowModel = model.modelForRow(i)
            if (rowModel && rowModel.count > 0) {
                for (let j = 0; j < rowModel.count; j++) {
                    let display = rowModel.data(rowModel.index(j, 0), Qt.DisplayRole) || ""
                    let lowerDisplay = display.toLowerCase()
                    
                    if (query !== "" && !lowerDisplay.includes(lowerQuery)) {
                        continue;
                    }

                    // Pre-fetch decoration (can be String or VariantMap/QIcon)
                    let decoration = rowModel.data(rowModel.index(j, 0), Qt.DecorationRole)

                    let item = {
                        "display": display,
                        "decoration": decoration !== undefined ? decoration : "",
                        "runnerModel": rowModel,
                        "modelIndex": j,
                        // ItemGridDelegate expectations
                        "hasChildren": false,
                        "url": "",
                        "favoriteId": "",
                        "hasActionList": false
                    }

                    if (query !== "" && lowerDisplay.startsWith(lowerQuery)) {
                        highPriority.push(item)
                    } else {
                        mediumPriority.push(item)
                    }
                }
            }
        }
        
        allResults = [...highPriority, ...mediumPriority]
        viewSwipeView.currentIndex = 0
    }

    onModelChanged: requestUpdate()
    onQueryChanged: requestUpdate()

    Connections {
        target: model
        function onCountChanged() { requestUpdate() }
        function onModelReset() { requestUpdate() }
    }

    // Internal list model to hold our flattened results
    ListModel {
        id: resultsListModel
        dynamicRoles: true
    }

    // Update the ListModel whenever allResults changes
    onAllResultsChanged: {
        resultsListModel.clear();
        for (let i = 0; i < allResults.length; i++) {
            resultsListModel.append(allResults[i]);
        }
    }

    SwipeView {
        id: viewSwipeView
        anchors.fill: parent
        clip: true
        focus: true
        interactive: true

        WheelHandler {
            property int wheelDelta: 0
            onWheel: (event) => {
                // Accumulate delta to handle smooth scrolling touchpads
                wheelDelta += event.rotation.x;
                if (Math.abs(wheelDelta) >= 20) {
                    if (wheelDelta > 0 && viewSwipeView.currentIndex > 0) {
                        viewSwipeView.decrementCurrentIndex();
                        wheelDelta = 0;
                    } else if (wheelDelta < 0 && viewSwipeView.currentIndex < viewSwipeView.count - 1) {
                        viewSwipeView.incrementCurrentIndex();
                        wheelDelta = 0;
                    }
                }
            }
        }

        onCurrentIndexChanged: {
            if (currentItem) {
                currentItem.forceActiveFocus();
            }
        }

        Repeater {
            model: searchResults.pageTotalCount

            ItemGridView {
                id: pagedGrid
                width: viewSwipeView.width
                height: viewSwipeView.height
                focus: true

                property int pageIndex: index
                // Explicitly capture the pageItemsCount to avoid undefined context in model callback
                property int capturedPageItemsCount: searchResults.pageItemsCount

                numberColumns: searchResults.numberColumns
                maxVisibleRows: searchResults.numberRows

                // Use the root-stabilized cell sizes to break the binding loop
                cellWidth: searchResults.cellSizeWidth
                cellHeight: searchResults.cellSizeHeight
                iconSize: searchResults.iconSize

                sourceModel: searchResults
                indexOffset: pageIndex * capturedPageItemsCount
                pageItemsCount: capturedPageItemsCount
                verticalScrollBarPolicy: ScrollBar.AlwaysOff

                model: KItemModels.KSortFilterProxyModel {
                    sourceModel: resultsListModel
                    filterRowCallback: (sourceRow, sourceParent) => {
                        let pSize = pagedGrid.capturedPageItemsCount;
                        let pIndex = pagedGrid.pageIndex;
                        return sourceRow >= (pIndex * pSize) &&
                               sourceRow < ((pIndex + 1) * pSize);
                    }
                }

                dragEnabled: false
                hoverEnabled: true

                onKeyNavUp: searchResults.keyNavUp()
                onKeyNavDown: searchResults.keyNavDown()

                onKeyNavLeft: {
                    if (viewSwipeView.currentIndex > 0) {
                        viewSwipeView.decrementCurrentIndex();
                    }
                }
                onKeyNavRight: {
                    if (viewSwipeView.currentIndex < viewSwipeView.count - 1) {
                        viewSwipeView.incrementCurrentIndex();
                    }
                }

                function trigger(index) {
                    let absoluteIndex = index + (pageIndex * capturedPageItemsCount);
                    if (absoluteIndex < allResults.length) {
                        let item = allResults[absoluteIndex];
                        try {
                            if (item.runnerModel && typeof item.runnerModel.trigger === "function") {
                                item.runnerModel.trigger(item.modelIndex, "", null);
                                root.toggle();
                            }
                        } catch (e) {
                            console.error("Error triggering search result:", e);
                        }
                    }
                }

                Component.onCompleted: {
                    if (pageIndex === viewSwipeView.currentIndex) {
                        forceActiveFocus();
                    }
                }
            }
        }
    }

    PageIndicator {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        visible: searchResults.pageTotalCount > 1
        currentIndex: viewSwipeView.currentIndex
        count: searchResults.pageTotalCount

        MouseArea {
            anchors.fill: parent
            onClicked: (mouse) => {
                if (searchResults.pageTotalCount > 0) {
                    let dotWidth = width / searchResults.pageTotalCount;
                    let index = Math.floor(mouse.x / dotWidth);
                    viewSwipeView.currentIndex = Math.max(0, Math.min(index, searchResults.pageTotalCount - 1));
                }
            }
        }
    }

    Component.onCompleted: {
        Qt.callLater(buildFlatResults)
    }
}
