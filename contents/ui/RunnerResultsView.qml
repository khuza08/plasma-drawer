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

    property var model: null
    property string query: ""

    property var allResults: []
    property int currentPage: 0

    // Satisfy ItemGridDelegate's expectation for directory model fetching
    function modelForRow(row) {
        return null;
    }

    // Debounce building results to batch rapid model updates from different runners
    Timer {
        id: updateTimer
        interval: 50
        repeat: false
        onTriggered: buildFlatResults()
    }

    function requestUpdate() {
        updateTimer.restart()
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
        currentPage = 0
    }

    onModelChanged: requestUpdate()
    onQueryChanged: requestUpdate()

    Connections {
        target: model
        function onCountChanged() { requestUpdate() }
        function onModelReset() { requestUpdate() }
    }

    // Internal list model to hold our flattened results
    // dynamicRoles: true is CRITICAL because different runners return different types for 'decoration'
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

    // Proxy model to provide paged results to ItemGridView
    property var resultsProxyModel: KItemModels.KSortFilterProxyModel {
        sourceModel: resultsListModel
        filterRowCallback: (sourceRow, sourceParent) => {
            let itemsPerPage = numberColumns * numberRows;
            return sourceRow >= (currentPage * itemsPerPage) &&
                   sourceRow < ((currentPage + 1) * itemsPerPage);
        }
    }

    ItemGridView {
        id: internalGridView
        
        // Use fixed dimensions to prevent binding loops with implicitWidth
        width: parent.width
        height: parent.height
        focus: true

        // Force the grid to match the reference sizing of the App Grid
        cellWidth: Math.floor(width / referenceColumns)
        cellHeight: Math.floor(height / referenceRows)
        numberColumns: searchResults.numberColumns
        
        iconSize: searchResults.iconSize
        
        // Pass ourselves as sourceModel so ItemGridDelegate finds modelForRow()
        sourceModel: searchResults
        model: resultsProxyModel
        
        dragEnabled: false

        onKeyNavUp: searchResults.keyNavUp()
        onKeyNavDown: searchResults.keyNavDown()

        // Handle item triggering
        function trigger(index) {
            let itemsPerPage = numberColumns * numberRows;
            let absoluteIndex = index + (currentPage * itemsPerPage);
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
    }

    // Keyboard navigation for pages
    Keys.onPressed: (event) => {
        let itemsPerPage = numberColumns * numberRows;
        let totalPages = Math.max(1, Math.ceil(allResults.length / itemsPerPage));

        if (event.key === Qt.Key_Left && currentPage > 0 && internalGridView.currentIndex % numberColumns === 0) {
            currentPage--;
            event.accepted = true;
        } else if (event.key === Qt.Key_Right && currentPage < totalPages - 1 && (internalGridView.currentIndex + 1) % numberColumns === 0) {
            currentPage++;
            event.accepted = true;
        }
    }

    Component.onCompleted: {
        Qt.callLater(buildFlatResults)
    }
}
