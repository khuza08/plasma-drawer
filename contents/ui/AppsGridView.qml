import QtQuick
import QtQuick.Controls

import org.kde.plasma.plasmoid
import org.kde.kquickcontrolsaddons
import org.kde.kirigami as Kirigami
import org.kde.kitemmodels as KItemModels

FocusScope {
    id: appsGrid

    signal keyNavUp
    signal keyNavDown

    property int iconSize: Kirigami.Units.iconSizes.huge
    
    readonly property int cellSizeWidth: iconSize * 2.5
    readonly property int minCellSizeHeight: iconSize * 2.0
    // cellSizeHeight grows to match the appsGrid height if there is some space left at the bottom
    readonly property int cellSizeHeight: {
        let rows = Math.floor(height / minCellSizeHeight);
        if (rows > 0) {
            return minCellSizeHeight + ((height % minCellSizeHeight) / rows);
        }
        return minCellSizeHeight;
    }

    property int numberColumns: 5
    property int numberRows: Math.max(1, Math.floor(height / cellSizeHeight))

    readonly property int itemsPerPage: Math.max(1, numberColumns * numberRows)
    readonly property int totalPages: Math.max(1, Math.ceil((currentModel ? currentModel.count : 0) / itemsPerPage))

    required property var model

    readonly property var currentItemGrid: (stackView.currentItem && "viewSwipeView" in stackView.currentItem) ? stackView.currentItem.viewSwipeView.currentItem : null
    readonly property var currentModel: appsGrid.model

    readonly property bool isAtRoot: stackView.depth <= 1

    implicitWidth: numberColumns * cellSizeWidth
    implicitHeight: numberRows * cellSizeHeight

    function tryEnterDirectory(directoryIndex) {
        let dir = currentModel.modelForRow(directoryIndex);
        if (dir && dir.hasChildren) {
            if (currentItemGrid) {
                let origin = Qt.point(0, 0);
                let item = currentItemGrid.itemAtIndex(directoryIndex % itemsPerPage);
                if (item) {
                    origin = Qt.point(  (item.x + (cellSizeWidth / 2)) - (currentItemGrid.width / 2), 
                                        (item.y + (cellSizeHeight / 2)) - (currentItemGrid.height / 2) - currentItemGrid.contentY )
                }
                stackView.push(pagedGridView, {model: dir, origin: origin});
            }
        }
    }

    function tryExitDirectory() {
        if (!isAtRoot) {
            stackView.pop();
        }
    }

    function returnToRootDirectory(doTransition = true) {
        if (!isAtRoot) {
            // Pops all items up until root
            stackView.pop(null, doTransition ? undefined : StackView.ReplaceTransition);
        }
    }

    function selectFirst() {
        if (currentItemGrid && currentItemGrid.count > 0) {
            currentItemGrid.trySelect(0, 0);
        }
    }

    function selectLast() {
        if (currentItemGrid && currentItemGrid.count > 0) {
            currentItemGrid.trySelect(currentItemGrid.lastRow(), 0);
        }
    }

    function removeSelection() {
        if (currentItemGrid) {
            currentItemGrid.currentIndex = -1;
        }
    }

    // Root Paging Component
    Component {
        id: pagedGridView
        
        FocusScope {
            id: pagedViewRoot
            anchors.fill: parent
            property var model: appsGrid.model
            property alias viewSwipeView: viewSwipeView
            property var origin: Qt.point(0, 0)
            focus: true
            
            readonly property int pageItemsCount: Math.max(1, appsGrid.numberColumns * appsGrid.numberRows)
            readonly property int pageTotalCount: {
                let count = (model ? model.count : 0);
                return Math.max(1, Math.ceil(count / pageItemsCount));
            }

            SwipeView {
                id: viewSwipeView
                anchors.fill: parent
                clip: true
                focus: true
                interactive: true
                
                Keys.onLeftPressed: (event) => {
                    if (currentIndex > 0) {
                        decrementCurrentIndex();
                        event.accepted = true;
                    }
                }
                Keys.onRightPressed: (event) => {
                    if (currentIndex < count - 1) {
                        incrementCurrentIndex();
                        event.accepted = true;
                    }
                }

                onCurrentIndexChanged: {
                    if (currentItem) {
                        currentItem.forceActiveFocus();
                        if (currentItem.currentIndex === -1) {
                            currentItem.currentIndex = 0;
                        }
                    }
                }

                Repeater {
                    model: pagedViewRoot.pageTotalCount
                    
                    ItemGridView {
                        id: pagedGrid
                        width: viewSwipeView.width
                        height: viewSwipeView.height
                        focus: true
                        
                        property int pageIndex: index
                        
                        numberColumns: appsGrid.numberColumns
                        maxVisibleRows: appsGrid.numberRows

                        cellWidth:  cellSizeWidth
                        cellHeight: cellSizeHeight
                        iconSize: appsGrid.iconSize

                        // Robust Paged Indexing
                        sourceModel: pagedViewRoot.model
                        indexOffset: pageIndex * pagedViewRoot.pageItemsCount
                        pageItemsCount: pagedViewRoot.pageItemsCount

                        model: KItemModels.KSortFilterProxyModel {
                            sourceModel: pagedViewRoot.model
                            filterRowCallback: (sourceRow, sourceParent) => {
                                return sourceRow >= (pageIndex * pagedViewRoot.pageItemsCount) && 
                                       sourceRow < ((pageIndex + 1) * pagedViewRoot.pageItemsCount);
                            }
                        }
                        
                        dragEnabled: false
                        hoverEnabled: true
                        
                        onKeyNavUp: appsGrid.keyNavUp()
                        onKeyNavDown: appsGrid.keyNavDown()
                        onRequestDirectoryEntry: (absoluteIndex) => appsGrid.tryEnterDirectory(absoluteIndex)
                        
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
                visible: pageTotalCount > 1
                currentIndex: viewSwipeView.currentIndex
                count: viewSwipeView.count

                MouseArea {
                    anchors.fill: parent
                    onClicked: (mouse) => {
                        if (count > 0) {
                            let dotWidth = width / count;
                            let index = Math.floor(mouse.x / dotWidth);
                            viewSwipeView.currentIndex = Math.max(0, Math.min(index, count - 1));
                        }
                    }
                }
            }
        }
    }

    StackView {
        id: stackView
        initialItem: pagedGridView
        
        implicitWidth: appsGrid.implicitWidth
        implicitHeight: appsGrid.implicitHeight
        anchors.top: parent.top
        anchors.bottom: parent.bottom 
        anchors.left: parent.left
        anchors.right: parent.right

        focus: true

        property var transitionDuration: (plasmoid && plasmoid.configuration.disableAnimations) ? 0 : Kirigami.Units.veryLongDuration / (plasmoid ? plasmoid.configuration.animationSpeedMultiplier : 1)

        pushEnter: (plasmoid && !plasmoid.configuration.disableAnimations) ? pushEnterTransition : instantEnterTransition
        pushExit:  (plasmoid && !plasmoid.configuration.disableAnimations) ? pushExitTransition  : instantExitTransition
        popEnter:  (plasmoid && !plasmoid.configuration.disableAnimations) ? popEnterTransition  : instantEnterTransition
        popExit:   (plasmoid && !plasmoid.configuration.disableAnimations) ? popExitTransition   : instantExitTransition

        replaceEnter: instantEnterTransition
        replaceExit: instantExitTransition

        Transition {
            id: pushEnterTransition

            NumberAnimation { 
                property: "x"; 
                from: pushEnterTransition.ViewTransition.item.origin ? pushEnterTransition.ViewTransition.item.origin.x : 0
                to: 0
                duration: stackView.transitionDuration
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                property: "y"
                from: pushEnterTransition.ViewTransition.item.origin ? pushEnterTransition.ViewTransition.item.origin.y : 0
                to: 0
                duration: stackView.transitionDuration
                easing.type: Easing.OutCubic
            }
            
            NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: stackView.transitionDuration * .5 }
            NumberAnimation { property: "scale"; from: 0; to: 1.0; duration: stackView.transitionDuration; easing.type: Easing.OutCubic }
        }

        Transition {
            id: pushExitTransition
            NumberAnimation { property: "y"; from: 0; to: -(appsGrid.iconSize * .5); duration: stackView.transitionDuration; easing.type: Easing.OutCubic }
            NumberAnimation { property: "opacity"; from: 1.0; to: 0; duration: stackView.transitionDuration * .5; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 1.0; to: 0.8; duration: stackView.transitionDuration * .5; easing.type: Easing.OutCubic }
        }

        Transition {
            id: popEnterTransition
           
            SequentialAnimation {
                PauseAnimation { duration: stackView.transitionDuration * .2 }
                ParallelAnimation {
                    NumberAnimation { property: "y"; from: -(appsGrid.iconSize * .5); to: 0; duration: stackView.transitionDuration; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: stackView.transitionDuration * .5; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "scale"; from: 0.8; to: 1.0; duration: stackView.transitionDuration; easing.type: Easing.OutCubic }
                }
            }
        }

        Transition {
            id: popExitTransition
            NumberAnimation {
                property: "x"
                from: 0
                to: popExitTransition.ViewTransition.item.origin ? popExitTransition.ViewTransition.item.origin.x : 0
                duration: stackView.transitionDuration * 1.5
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                property: "y"
                from: 0
                to: popExitTransition.ViewTransition.item.origin ? popExitTransition.ViewTransition.item.origin.y : 0
                duration: stackView.transitionDuration * 1.5
                easing.type: Easing.OutCubic
            }
            
            NumberAnimation { property: "opacity"; from: 1.0; to: 0; duration: stackView.transitionDuration * .75; easing.type: Easing.OutQuint }
            NumberAnimation { property: "scale"; from: 1.0; to: 0; duration: stackView.transitionDuration * 1.5; easing.type: Easing.OutCubic }
        }

        Transition {
            id: instantEnterTransition

            PropertyAction { property: "opacity"; value: 1.0 }
            PropertyAction { property: "scale"; value: 1.0 }
        }

        Transition {
            id: instantExitTransition

            PropertyAction { property: "opacity"; value: 0 }
            PropertyAction { property: "scale"; value: 0 }
        }
    }
}
