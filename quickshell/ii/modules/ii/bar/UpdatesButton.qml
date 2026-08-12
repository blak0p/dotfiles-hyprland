import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

RippleButton {
    id: root

    property int buttonPadding: 5
    implicitWidth: distroIcon.width + buttonPadding * 2
    implicitHeight: distroIcon.height + buttonPadding * 2
    buttonRadius: Appearance.rounding.full
    colBackground: Appearance.colors.colLayer1Hover
    colBackgroundHover: Appearance.colors.colLayer1Hover
    colRipple: Appearance.colors.colLayer1Active

    onClicked: {
        Quickshell.execDetached(["bash", "-c", Config.options.apps.update]);
    }

    CustomIcon {
        id: distroIcon
        anchors.centerIn: parent
        width: 24
        height: 24
        source: Updates.available && Updates.count > 0 ? "cachy-update-updates.svg" : "cachy-update.svg"
        colorize: false
    }

    PopupToolTip {
        extraVisibleCondition: root.hovered
        text: Updates.available && Updates.count > 0
            ? Translation.tr("Check for updates. %1 packages pending.").arg(Updates.count)
            : Translation.tr("Check for updates")
    }
}