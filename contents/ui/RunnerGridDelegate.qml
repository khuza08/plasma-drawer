import QtQuick

import org.kde.plasma.plasmoid
import org.kde.plasma.components 3.0 as PC3
import org.kde.kirigami as Kirigami

Item {
    id: item

    property var modelProxy: null
    property int iconSize: Kirigami.Units.iconSizes.large
    property bool showLabel: true
    property bool isCurrentItem: false

    Accessible.role: Accessible.MenuItem
    Accessible.name: modelProxy ? modelProxy.display : ""

    Rectangle {
        id: selectionHighlight
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        radius: Kirigami.Units.smallSpacing
        color: Kirigami.Theme.highlightColor
        opacity: isCurrentItem ? 0.3 : 0
        visible: isCurrentItem

        Behavior on opacity { OpacityAnimator { duration: Kirigami.Units.shortDuration } }
    }

    Rectangle {
        id: displayBox
        width: iconSize
        height: width
        y: (item.height * 0.4) - (height / 2)
        anchors.horizontalCenter: parent.horizontalCenter
        color: "transparent"

        Kirigami.Icon {
            id: icon
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            animated: false
            source: modelProxy ? modelProxy.decoration : ""
            roundToIconSize: width > Kirigami.Units.iconSizes.huge ? false : true
        }
    }

    PC3.Label {
        id: label

        visible: showLabel

        anchors {
            top: displayBox.bottom
            topMargin: Kirigami.Units.smallSpacing
            left: parent.left
            leftMargin: Kirigami.Units.smallSpacing
            right: parent.right
            rightMargin: Kirigami.Units.smallSpacing
        }

        horizontalAlignment: Text.AlignHCenter

        elide: Text.ElideRight
        wrapMode: Text.NoWrap

        text: modelProxy ? modelProxy.display : ""
        color: drawerTheme.textColor

        fontSizeMode: Text.Fit
        minimumPointSize: 8
        font.pointSize: 9
        maximumLineCount: 2
    }
}
