/***************************************************************************
 *   Copyright (C) 2014-2015 by Eike Hein <hein@kde.org>                   *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid

import org.kde.plasma.core as PlasmaCore
import org.kde.ksvg as KSvg

import org.kde.plasma.private.kicker as Kicker
import org.kde.kitemmodels as KItemModels

import "../code/KickerCompat.js" as KickerCompat

PlasmoidItem {
    id: kicker

    anchors.fill: parent

    signal reset

    preferredRepresentation: fullRepresentation

    compactRepresentation: null
    fullRepresentation: compactRepresentation

    property Item dragSource: null

    property alias systemFavoritesModel: systemModel.favoritesModel

    // Runtime Kicker API validation
    readonly property bool kickerAPIAvailable: KickerCompat.validateKickerAPI(Kicker).success
    readonly property var kickerValidation: KickerCompat.validateKickerAPI(Kicker)

    Component.onCompleted: {
        // Log compatibility info on startup
        KickerCompat.logCompatibilityInfo();

        if (!kickerAPIAvailable) {
            console.error("[Plasma Drawer] Kicker API validation failed:", kickerValidation.message);
            console.error("[Plasma Drawer] Some features may not work correctly.");
        }
    }

    Component {
        id: compactRepresentation
        CompactRepresentation {}
    }

    Component {
        id: menuRepresentation
        MenuRepresentation {}
    }

    Connections {
        target: systemFavoritesModel

        function onCountChanged() {
            if (systemFavoritesModel.count == 0) {
                plasmoid.configuration.showSystemActions = false;
            }
        }

        function onFavoritesChanged() {
            if (target.count > 0 && target.favorites.toString() != plasmoid.configuration.favoriteSystemActions.toString()) {
                plasmoid.configuration.favoriteSystemActions = target.favorites;
            }
        }
    }

    readonly property DrawerTheme drawerTheme: DrawerTheme {}

    readonly property Kicker.AppsModel appsModel: Kicker.AppsModel {
        autoPopulate: true

        flat: false
        showTopLevelItems: true
        sorted: false
        showSeparators: false
        paginate: false

        appletInterface: kicker
        appNameFormat: plasmoid.configuration.appNameFormat

        Component.onCompleted: {
            appsModel.refresh();
        }
    }

    Kicker.SystemModel {
        id: systemModel

        Component.onCompleted: {
            systemFavoritesModel.enabled = true;
            systemFavoritesModel.maxFavorites = 8;

            // Favorites set on MenuRepresentation visible instead to ensure that system actions are
            // available at set time
        }
    }

    // Kicker.RunnerModel no longer has the deleteWhenEmpty property, which means we must filter
    // out the empty results sections ourselves using a wrapper FilterProxyModel
    KItemModels.KSortFilterProxyModel {
        id: runnerModel

        property alias query: kickerRunnerModel.query

        sourceModel: Kicker.RunnerModel {
            id: kickerRunnerModel
            appletInterface: kicker
            runners: plasmoid.configuration.searchRunners
            onCountChanged: {
                for (let i = 0; i < count; i++) {
                    kickerRunnerModel.modelForRow(i).countChanged.connect(runnerModel.invalidateFilter);
                }
            }
        }

        filterRowCallback: (sourceRow, sourceParent) => {
            return sourceModel.modelForRow(sourceRow).count > 0;
        }

        function modelForRow(proxyRow) {
            let sourceRow = runnerModel.mapToSource(runnerModel.index(proxyRow, 0)).row;
            return sourceModel.modelForRow(sourceRow);
        }
    }

    Kicker.DragHelper {
        id: dragHelper
    }

    Kicker.ProcessRunner {
        id: processRunner;
    }

    KSvg.FrameSvgItem {
        id : highlightItemSvg

        visible: false

        imagePath: "widgets/viewitem"
        prefix: "hover"
    }

    KSvg.FrameSvgItem {
        id : panelSvg

        visible: false

        imagePath: "widgets/panel-background"
    }

    function resetDragSource() {
        dragSource = null;
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Edit Applications...")
            icon.name: "kmenuedit"
            onTriggered: processRunner.runMenuEditor()
        }
    ]
}
