import QtQuick
import QtQuick.Controls

import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

FocusScope {
    id: searchResults

    signal keyNavUp
    signal keyNavDown

    property int numberColumns: 8
    property int numberRows: 3

    readonly property int cellSizeWidth: Math.floor(width / numberColumns)
    readonly property int cellSizeHeight: Math.floor(height / numberRows)

    property int iconSize: Math.max(Kirigami.Units.iconSizes.small, Math.min(Kirigami.Units.iconSizes.huge, cellSizeHeight * 0.55))

    readonly property int itemsPerPage: Math.max(1, numberColumns * numberRows)
    readonly property int totalPages: Math.max(1, Math.ceil((allResults.length) / itemsPerPage))

    property var model: null
    property string query: ""
    property bool shrinkIconsToNative: false

    property var allResults: []
    property int currentPage: 0

    implicitWidth: numberColumns * cellSizeWidth
    implicitHeight: numberRows * cellSizeHeight

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

    // Build flat array from all runner results
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
                    
                    // Pre-fetch decoration to avoid repeated C++ calls
                    let decoration = rowModel.data(rowModel.index(j, 0), Qt.DecorationRole)

                    let item = {
                        model: rowModel,
                        index: j,
                        display: display,
                        decoration: decoration
                    }

                    if (query !== "") {
                        if (lowerDisplay.startsWith(lowerQuery)) {
                            highPriority.push(item)
                        } else if (lowerDisplay.includes(lowerQuery)) {
                            mediumPriority.push(item)
                        }
                    } else {
                        highPriority.push(item)
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

    Component.onCompleted: {
        Qt.callLater(buildFlatResults)
    }

    property int currentIndex: -1

    GridView {
        id: resultsGrid
        anchors.fill: parent
        cellWidth: cellSizeWidth
        cellHeight: cellSizeHeight
        interactive: false
        
        // Only show current page
        model: allResults.slice(currentPage * itemsPerPage, (currentPage + 1) * itemsPerPage)

        delegate: Item {
            width: resultsGrid.cellWidth
            height: resultsGrid.cellHeight

            readonly property int itemIndex: index + (currentPage * itemsPerPage)
            
            RunnerGridDelegate {
                anchors.fill: parent
                iconSize: searchResults.iconSize
                modelProxy: modelData
                isCurrentItem: itemIndex === currentIndex
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    currentIndex = itemIndex
                    if (modelData && modelData.model) {
                        modelData.model.trigger(modelData.index, "", null)
                        root.toggle()
                    }
                }
            }
        }
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Up) {
            if (currentIndex >= numberColumns) {
                currentIndex -= numberColumns
            } else if (currentIndex >= 0) {
                keyNavUp()
            }
        } else if (event.key === Qt.Key_Down) {
            if (currentIndex < allResults.length - numberColumns) {
                currentIndex += numberColumns
            } else if (currentIndex >= 0) {
                keyNavDown()
            }
        } else if (event.key === Qt.Key_Left) {
            if (currentIndex > 0 && currentIndex % numberColumns !== 0) {
                currentIndex--
            } else if (currentPage > 0) {
                currentPage--
            }
        } else if (event.key === Qt.Key_Right) {
            if (currentIndex < allResults.length - 1 && (currentIndex + 1) % numberColumns !== 0) {
                currentIndex++
            } else if (currentPage < totalPages - 1) {
                currentPage++
            }
        } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            if (currentIndex !== -1 && currentIndex < allResults.length) {
                let item = allResults[currentIndex]
                item.model.trigger(item.index, "", null)
                root.toggle()
            }
        }
    }
}
