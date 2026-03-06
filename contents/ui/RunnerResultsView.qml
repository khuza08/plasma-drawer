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
    property bool shrinkIconsToNative: false

    property var allResults: []
    property int currentPage: 0

    implicitWidth: numberColumns * cellSizeWidth
    implicitHeight: numberRows * cellSizeHeight

    // Build flat array from all runner results
    function buildFlatResults() {
        allResults = []
        if (!model) {
            console.log("No model!")
            return
        }

        console.log("Building results, model.count:", model.count)
        for (let i = 0; i < model.count; i++) {
            let rowModel = model.modelForRow(i)
            if (rowModel && rowModel.count > 0) {
                console.log("Row", i, "has", rowModel.count, "items")
                for (let j = 0; j < rowModel.count; j++) {
                    allResults.push({
                        model: rowModel,
                        index: j
                    })
                }
            }
        }
        console.log("Total results:", allResults.length)
        currentPage = 0
        updatePage()
    }

    onModelChanged: buildFlatResults()

    Connections {
        target: model
        function onCountChanged() { buildFlatResults() }
        function onModelReset() { buildFlatResults() }
    }

    Component.onCompleted: {
        Qt.callLater(buildFlatResults)
    }

    property int currentIndex: -1

    function updatePage() {
        pageContainer.children = []
        pageComponent.createObject(pageContainer, {page: currentPage})
    }

    Component {
        id: pageComponent

        Item {
            id: pageItem
            property int page: 0
            anchors.fill: parent

            Repeater {
                model: Math.min(itemsPerPage, allResults.length - (pageItem.page * itemsPerPage))

                Rectangle {
                    property int itemIndex: index + (pageItem.page * itemsPerPage)
                    property var itemData: itemIndex < allResults.length ? allResults[itemIndex] : null

                    readonly property int row: Math.floor(index / numberColumns)
                    readonly property int col: index % numberColumns

                    x: col * cellSizeWidth
                    y: row * cellSizeHeight
                    width: cellSizeWidth
                    height: cellSizeHeight

                    color: "transparent"

                    QtObject {
                        id: modelProxy
                        property var item: itemData
                        property string display: itemData && itemData.model ? (itemData.model.data(itemData.model.index(itemData.index, 0), Qt.DisplayRole) || "") : ""
                        property var decoration: itemData && itemData.model ? itemData.model.data(itemData.model.index(itemData.index, 0), Qt.DecorationRole) : ""
                    }

                    RunnerGridDelegate {
                        anchors.fill: parent
                        iconSize: searchResults.iconSize
                        modelProxy: modelProxy
                        isCurrentItem: itemIndex === currentIndex
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            currentIndex = itemIndex
                            if (itemData) {
                                itemData.model.trigger(itemData.index, "", null)
                                root.toggle()
                            }
                        }
                    }

                    Component.onCompleted: {
                        console.log("Item:", itemIndex, "display:", modelProxy.display, "icon:", modelProxy.decoration)
                    }
                }
            }
        }
    }

    Item {
        id: pageContainer
        anchors.fill: parent
    }

    onCurrentPageChanged: {
        updatePage()
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
                updatePage()
            }
        } else if (event.key === Qt.Key_Right) {
            if (currentIndex < allResults.length - 1 && (currentIndex + 1) % numberColumns !== 0) {
                currentIndex++
            } else if (currentPage < totalPages - 1) {
                currentPage++
                updatePage()
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
