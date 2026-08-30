import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import qs.Core

Item {
    id: root

    property var notifData
    property int iconSize: Constants.size4Xl
    property color iconColor: Theme.accent
    property color bgColor: Theme.bgSecondary
    property bool hasAppIcon: (notifData && notifData.appIcon && notifData.appIcon !== "") || (notifData && notifData.image)
    property bool isUrgencyIcon: !hasAppIcon

    function getUrgencyIcon() {
        if (!notifData)
            return "info-filled";

        if (notifData.urgency === 2)
            return "warning";

        if (notifData.urgency === 0)
            return "info";

        return "info-filled";
    }

    SvgIcon {
        anchors.fill: parent
        visible: !root.hasAppIcon
        icon: root.hasAppIcon ? "" : getUrgencyIcon()
        iconSize: root.isUrgencyIcon ? Constants.sizeLg : Constants.size2Xl
        iconColor: root.iconColor
        flat: root.isUrgencyIcon
        bgColor: root.isUrgencyIcon ? "transparent" : root.bgColor
        isCircle: false
    }

    Rectangle {
        id: imageBg

        anchors.fill: parent
        visible: root.hasAppIcon
        color: "transparent"
        radius: Constants.sizeLg

        Image {
            id: appImage

            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: {
                if (!root.notifData)
                    return "";

                if (root.notifData.image)
                    return root.notifData.image;

                if (root.notifData.appIcon && root.notifData.appIcon !== "") {
                    if (root.notifData.appIcon.startsWith("file://"))
                        return root.notifData.appIcon;

                    if (root.notifData.appIcon.startsWith("/"))
                        return "file://" + root.notifData.appIcon;

                    return "image://icon/" + root.notifData.appIcon;
                }
                return "";
            }
            sourceSize.width: root.iconSize
            sourceSize.height: root.iconSize
            layer.enabled: true

            layer.effect: OpacityMask {

                maskSource: Rectangle {
                    width: appImage.width
                    height: appImage.height
                    radius: Constants.sizeSm
                }

            }

        }

    }

}
