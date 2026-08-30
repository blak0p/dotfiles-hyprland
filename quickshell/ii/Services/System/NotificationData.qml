pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

QtObject {
    id: root

    property Notification notification
    property string notificationId
    property string summary: ""
    property string body: ""
    property string appName: "System"
    property string appIcon: ""
    property string image: ""

    property int urgency: NotificationUrgency.Normal
    property double timestamp: new Date().getTime()
    property bool popup: true
    property bool isDnd: false
    property bool closed: false
    
    property bool isTransient: summary === "Volume" || summary === "Brightness" || summary === "Microphone" || summary === "Power Menu" || body.includes("Taking shot in")
    
    property real progress: 1.0 

    property var locks: new Set()

    property PropertyAnimation progressAnim: PropertyAnimation {
        target: root
        property: "progress"
        from: 1.0
        to: 0.0
        duration: {
            if (root.summary === "Power Menu") return 10000;
            if (root.summary === "Volume" || root.summary === "Brightness" || root.summary === "Microphone") return 1500;
            return 5000;
        }
        running: root.popup && (!root.isDnd || root.urgency === 2) && !root.closed && root.urgency !== 2
        onFinished: {
            if (root.summary === "Power Menu") {
            }
            root.popup = false;
        }
    }

    readonly property Connections conn: Connections {
        function onClosed() {
            root.close();
        }

        function onSummaryChanged() {
            root.summary = root.notification.summary;
        }

        function onBodyChanged() {
            root.body = root.notification.body;
            
            if (root.popup && (!root.isDnd || root.urgency === 2) && !root.closed && root.urgency !== 2) {
                root.progress = 1.0;
                root.progressAnim.restart();
            }
        }

        function onAppIconChanged() {
            root.appIcon = root.notification.appIcon;
        }

        function onAppNameChanged() {
            root.appName = root.notification.appName;
        }

        function onImageChanged() {
            root.image = root.notification.image;
        }



        function onUrgencyChanged() {
            root.urgency = root.notification.urgency;
        }

        target: root.notification
    }

    function lock(item) {
        locks.add(item);
        if (progressAnim.running) {
            progressAnim.pause();
        }
    }

    function unlock(item) {
        locks.delete(item);
        if (locks.size === 0 && popup && !root.closed) {
            progressAnim.resume();
        }
    }

    function close() {
        if (closed) return;
        closed = true;
        popup = false;
        notification?.dismiss();
    }

    Component.onCompleted: {
        if (!notification) return;
        notificationId = notification.id;
        summary = notification.summary;
        body = notification.body;
        appIcon = notification.appIcon;
        appName = notification.appName;
        image = notification.image;
        urgency = notification.urgency;
    }
}
