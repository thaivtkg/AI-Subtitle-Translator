pragma Singleton
import QtQuick 2.15

QtObject {
    // --- Backgrounds ---
    readonly property color bgApp: "#0B1020"
    readonly property color bgSurface: "#111827"
    readonly property color bgSurfaceElevated: "#172033"
    readonly property color bgSurfaceSoft: "#1B263B"
    readonly property color border: "#273247"

    // --- Accents ---
    readonly property color accentPurple: "#8B5CF6"
    readonly property color accentPink: "#EC4899"
    readonly property color accentCyan: "#38BDF8"
    readonly property color success: "#34D399"
    readonly property color warning: "#FBBF24"
    readonly property color danger: "#F43F5E"

    // --- Text ---
    readonly property color textPrimary: "#F8FAFC"
    readonly property color textSecondary: "#CBD5E1"
    readonly property color textMuted: "#94A3B8"
    readonly property color textDisabled: "#64748B"

    // --- Spacing ---
    readonly property int spaceXs: 4
    readonly property int spaceSmall: 8
    readonly property int spaceMedium: 16
    readonly property int spaceLarge: 24
    readonly property int spaceXl: 32

    // --- Radius & Animation ---
    readonly property int radius: 6
    readonly property int animDuration: 150
}