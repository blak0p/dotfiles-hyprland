// UsageTracker.qml — Public interface for a usage tracking service.
//
// This file is shipped with dotfiles-hyprland. It provides the SHAPE
// of the service: properties, signals, and a public function
// `refresh()` that consumers (e.g. BarContent.qml) can read from.
//
// The IMPLEMENTATION is not in this public repo. The public version
// only sets up empty default values. Hosts that want real data provide
// their own UsageTracker.qml override in their custom layer (in
// ~/.config/quickshell/services/), which replaces this file at load
// time.
//
// Without a custom layer deployed, the bar widget shows "—" and the
// popup is empty. The service is fully usable for layout/UI testing
// without the implementation.

pragma Singleton
pragma ComponentBehavior: Bound

import qs
import QtQuick
import Quickshell

Singleton {
    id: root

    // --- Configuration (defaults are placeholders) ---
    readonly property string containerName: ""
    readonly property int updateInterval: 60000

    // --- State ---
    property bool popupOpen: false

    // Weekly (secondary tier)
    property real weeklyRemainingPercent: -1
    property string weeklyResetDescription: ""
    property string weeklyTimeRemaining: ""
    property int weeklyWindowMinutes: 0

    // Primary (session) tier
    property bool hasPrimary: false
    property real primaryRemainingPercent: -1
    property string primaryTimeRemaining: ""

    // Tertiary tier
    property bool hasTertiary: false
    property real tertiaryRemainingPercent: -1
    property string tertiaryResetDescription: ""

    // Reset / Review credits
    property int resetCreditsAvailable: 0
    property string resetCreditsList: ""
    property int creditsRemaining: 0

    // Identity
    property string accountEmail: ""
    property string loginMethod: ""
    property string plan: ""

    // Model / version
    property string model: ""
    property string version: ""

    // Data metadata
    property string dataConfidence: ""
    property string updatedAt: ""
    property string statusText: ""

    // Status flags
    property bool hasError: false
    property bool loading: false
    property bool containerRunning: false
    property string statusIndicator: ""
    property string statusDescription: ""
    property string statusURL: ""

    // --- Derived display properties ---
    property real displayPercent: weeklyRemainingPercent >= 0 ? weeklyRemainingPercent : primaryRemainingPercent
    property string displayTime: root.weeklyTimeRemaining.length > 0 ? root.weeklyTimeRemaining : root.primaryTimeRemaining

    property string lastUpdatedText: {
        if (root.updatedAt.length === 0) return ""
        return root.formatTimeAgo(root.updatedAt)
    }

    // Compact text shown in the bar widget. With no implementation
    // deployed, this shows "—" (em dash). A custom layer override of
    // this service can populate the properties above to provide real
    // values, and `compactText` will reflect them automatically.
    property string compactText: {
        if (loading) return "…"
        if (hasError) return "—"
        if (displayPercent < 0) return "—"
        return Math.round(displayPercent) + "% • " + displayTime
    }

    // --- Signals ---
    signal usageUpdated()

    // --- Public API (no-op by default; real implementation overrides) ---
    function refresh() {
        // Override in the implementation
    }

    function formatTimeAgo(isoDate) {
        if (!isoDate || isoDate.length === 0) return ""
        try {
            var now = new Date()
            var then = new Date(isoDate)
            var diffMs = now.getTime() - then.getTime()
            if (diffMs < 0) return "just now"
            var secs = Math.floor(diffMs / 1000)
            if (secs < 10) return "just now"
            if (secs < 60) return secs + "s ago"
            var mins = Math.floor(secs / 60)
            if (mins < 60) return mins + "m ago"
            var hours = Math.floor(mins / 60)
            if (hours < 24) return hours + "h ago"
            var days = Math.floor(hours / 24)
            return days + "d ago"
        } catch (e) {
            return ""
        }
    }

    function formatTimeRemaining(isoDate) {
        if (!isoDate || isoDate.length === 0) return ""
        try {
            var now = new Date()
            var reset = new Date(isoDate)
            var diff = reset.getTime() - now.getTime()
            if (diff <= 0) return "resetting…"
            var totalMinutes = Math.floor(diff / 60000)
            var hours = Math.floor(totalMinutes / 60)
            var minutes = totalMinutes % 60
            if (hours >= 24) {
                var days = Math.floor(hours / 24)
                hours = hours % 24
                return days + "d " + hours + "h"
            }
            return hours + "h " + minutes + "m"
        } catch (e) {
            return ""
        }
    }
}
