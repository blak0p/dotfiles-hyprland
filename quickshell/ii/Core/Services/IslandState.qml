pragma Singleton

import QtQuick
import Quickshell
import qs.Core
import qs.Core.Services

QtObject {
    id: root

    readonly property int modeIdle: 0
    readonly property int modeCompactToast: 1
    readonly property int modeExpandedNotch: 2

    property int mode: root.modeIdle
    property var activeNotification: null
    property var queue: []
    property int queueCount: queue.length

    function isCritical(notif) {
        if (!notif) return false;
        if (typeof notif.urgency === "number") return notif.urgency === 2;
        if (typeof notif.urgency === "string") return notif.urgency.toLowerCase() === "critical";
        return false;
    }

    function isClosed(notif) {
        if (!notif) return true;
        if (notif.closed) return true;
        if (notif.popup !== undefined && !notif.popup && mode === root.modeIdle) return true;
        return false;
    }

    function pushNotification(notifData) {
        if (!notifData) return;

        // If game mode / DND is on and urgency is not critical, don't show toast
        if (notifData.isDnd && !isCritical(notifData)) return;

        // 1. If nothing is active, activate directly as solitary (7s)
        if (!activeNotification || isClosed(activeNotification)) {
            notifData.appMessageCount = 1;
            notifData.isBurst = false;
            activeNotification = notifData;
            mode = root.modeCompactToast;
            if (activeNotification.timer) {
                activeNotification.timer.interval = 7000;
                if (activeNotification.timer.running) activeNotification.timer.restart();
            }
            return;
        }

        // 2. Same App as Active Notification -> Coalesce in-place with burst timer (2.5s)
        if (activeNotification.appName && notifData.appName && activeNotification.appName === notifData.appName) {
            let currentCount = (activeNotification.appMessageCount || 1) + 1;
            notifData.appMessageCount = currentCount;
            notifData.isBurst = true;
            activeNotification = notifData;
            if (activeNotification.timer) {
                activeNotification.timer.interval = 2500;
                if (activeNotification.timer.running) activeNotification.timer.restart();
            }
            return;
        }

        // 3. Critical notification immediately preempts current toast
        if (isCritical(notifData)) {
            if (activeNotification && !isClosed(activeNotification)) {
                let newQueue = [activeNotification].concat(queue.filter(n => n !== notifData && n !== activeNotification));
                queue = newQueue;
                queueCount = queue.length;
            }
            notifData.appMessageCount = 1;
            notifData.isBurst = false;
            activeNotification = notifData;
            mode = root.modeCompactToast;
            if (activeNotification.timer) {
                activeNotification.timer.interval = 7000;
                if (activeNotification.timer.running) activeNotification.timer.restart();
            }
            return;
        }

        // 4. Different app -> check if already exists in queue (coalesce inside queue)
        let foundIdx = -1;
        for (let i = 0; i < queue.length; i++) {
            if (queue[i] && queue[i].appName && notifData.appName && queue[i].appName === notifData.appName) {
                foundIdx = i;
                break;
            }
        }

        if (foundIdx !== -1) {
            let qCount = (queue[foundIdx].appMessageCount || 1) + 1;
            notifData.appMessageCount = qCount;
            notifData.isBurst = true;
            let newQueue = queue.slice(0);
            newQueue[foundIdx] = notifData;
            queue = newQueue;
            queueCount = queue.length;
        } else {
            notifData.appMessageCount = 1;
            notifData.isBurst = false;
            let newQueue = queue.concat([notifData]);
            queue = newQueue;
            queueCount = queue.length;
        }
    }

    function onNotificationFinished(notifData) {
        if (activeNotification === notifData || (activeNotification && notifData && activeNotification.notificationId === notifData.notificationId)) {
            advanceQueue();
        } else {
            queue = queue.filter(n => n !== notifData && (n.notificationId ? n.notificationId !== notifData?.notificationId : true) && !isClosed(n));
            queueCount = queue.length;
        }
    }

    function pauseActiveTimer() {
        if (activeNotification && activeNotification.timer && typeof activeNotification.timer.stop === "function") {
            activeNotification.timer.stop();
        }
    }

    function resumeActiveTimer() {
        if (activeNotification && activeNotification.timer && typeof activeNotification.timer.restart === "function") {
            activeNotification.timer.restart();
        }
    }

    function dismissActive() {
        if (activeNotification) {
            let notifId = activeNotification.notificationId;
            if (typeof activeNotification.close === "function") {
                activeNotification.close();
            } else if (activeNotification.notification && typeof activeNotification.notification.dismiss === "function") {
                activeNotification.notification.dismiss();
            }
            if (activeNotification.timer && typeof activeNotification.timer.stop === "function") {
                activeNotification.timer.stop();
            }
            if (notifId !== undefined && typeof Notifications !== "undefined" && typeof Notifications.discardNotification === "function") {
                Notifications.discardNotification(notifId);
                return;
            }
        }
        advanceQueue();
    }

    function advanceQueue() {
        let next = null;
        let remaining = [];
        for (let i = 0; i < queue.length; i++) {
            let item = queue[i];
            if (item && !isClosed(item) && !next) {
                next = item;
            } else if (item && !isClosed(item)) {
                remaining.push(item);
            }
        }
        queue = remaining;
        queueCount = queue.length;

        if (next) {
            activeNotification = next;
            mode = root.modeCompactToast;
            if (activeNotification.timer) {
                activeNotification.timer.interval = (activeNotification.isBurst || activeNotification.appMessageCount > 1) ? 3000 : 7000;
                if (activeNotification.timer.running) activeNotification.timer.restart();
            }
        } else {
            activeNotification = null;
            mode = root.modeIdle;
            if (AppState.activePopup === "dynamicIslandNotch") {
                AppState.activePopup = "";
            }
        }
    }

    function dismissAll() {
        if (typeof Notifications !== "undefined" && typeof Notifications.discardAllNotifications === "function") {
            Notifications.discardAllNotifications();
        }
        queue = [];
        queueCount = 0;
        if (activeNotification) {
            if (typeof activeNotification.close === "function") {
                activeNotification.close();
            } else if (activeNotification.notification && typeof activeNotification.notification.dismiss === "function") {
                activeNotification.notification.dismiss();
            }
            if (activeNotification.timer && typeof activeNotification.timer.stop === "function") {
                activeNotification.timer.stop();
            }
        }
        activeNotification = null;
        mode = root.modeIdle;
    }

    function expand() {
        if (!activeNotification) return;
        if (typeof activeNotification.lock === "function") {
            activeNotification.lock("dynamicIslandNotch");
        }
        mode = root.modeExpandedNotch;
        AppState.activePopup = "dynamicIslandNotch";
    }

    function collapse() {
        if (activeNotification && typeof activeNotification.unlock === "function") {
            activeNotification.unlock("dynamicIslandNotch");
        }
        if (AppState.activePopup === "dynamicIslandNotch") {
            AppState.activePopup = "";
        }
        if (mode === root.modeExpandedNotch) {
            mode = (activeNotification && !isClosed(activeNotification)) ? root.modeCompactToast : root.modeIdle;
        }
    }
}
