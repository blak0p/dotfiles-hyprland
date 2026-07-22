pragma ComponentBehavior: Bound

/*
 * CodexBarWidget — Compact usage monitor for Codex/OpenAI in the bar.
 *
 * Shows "codex" label + compact usage text. Click to toggle the
 * detailed popup (CodexBarPopup). Click outside to close.
 *
 * Disabled (invisible) when Config.options.codexbar.queryCommand is empty.
 */

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

MouseArea {
    id: root
    implicitWidth: rowLayout.implicitWidth + 10 * 2
    implicitHeight: Appearance.sizes.barHeight

    visible: CodexBar.enabled
    hoverEnabled: false
    cursorShape: Qt.PointingHandCursor

    property bool _open: false

    onClicked: {
        root._open = !root._open
        if (root._open) CodexBar.refresh()
    }

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent

        StyledText {
            text: "codex"
            color: Appearance.colors.colOnLayer1
            font.pixelSize: Appearance.font.pixelSize.large
        }

        StyledText {
            text: CodexBar.compactText
            color: Appearance.colors.colOnLayer1
            font.pixelSize: Appearance.font.pixelSize.small
        }
    }

    // Fake hover target — always reports "hovered" so StyledPopup activates
    Item {
        id: fakeHover
        property bool containsMouse: true
    }

    // Popup LazyLoader
    LazyLoader {
        id: popupLoader
        active: root._open
        component: CodexBarPopup {
            hoverTarget: fakeHover
        }
    }

    // Close popup on outside click
    HyprlandFocusGrab {
        id: grab
        windows: [popupLoader.item]
        active: root._open
        onActiveChanged: if (!active) root._open = false
    }

    // Load initial data when enabled
    Component.onCompleted: {
        if (CodexBar.enabled) CodexBar.refresh()
    }
}