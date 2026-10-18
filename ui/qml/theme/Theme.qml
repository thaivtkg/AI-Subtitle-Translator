pragma Singleton
import QtQuick 2.15

QtObject {
    // --- Legacy / Base Backgrounds (Preserved for compatibility) ---
    readonly property color bgApp: "#090D16"
    readonly property color bgSurface: "#0F172A"
    readonly property color bgSurfaceElevated: "#172033"
    readonly property color bgSurfaceSoft: "#1E293B"
    readonly property color border: "#273247"
    readonly property color borderDisabled: "#273247"

    // --- Ultra-Gloss Liquid Glass Surfaces (Desktop Bleed-Through) ---
    readonly property color glassBackground: Qt.rgba(1.0, 1.0, 1.0, 0.15)         // Lớp phủ kính sáng
    readonly property color glassIslandSurface: Qt.rgba(1.0, 1.0, 1.0, 0.16)       // Bề mặt đảo kính nổi sáng xuyên thấu
    readonly property color glassIslandActive: Qt.rgba(0.0, 0.40, 1.0, 0.35)       // Vùng chọn nổi bật
    readonly property color glassPodLuminous: Qt.rgba(1.0, 1.0, 1.0, 0.85)         // Hộp thẻ kính mờ trắng sáng câu gốc
    readonly property color glassPodRaised: Qt.rgba(1.0, 1.0, 1.0, 0.90)           // Hộp nổi bật câu dịch

    // --- Specular Bevels & Refractive Rims ---
    readonly property color glassBorderSpecularUpper: Qt.rgba(1.0, 1.0, 1.0, 0.95) // Viền bóng mép kính trên (Double Specular Rim)
    readonly property color glassBorderSpecularLower: Qt.rgba(1.0, 1.0, 1.0, 0.45) // Viền mép dưới
    readonly property color glassBorderSubtle: Qt.rgba(1.0, 1.0, 1.0, 0.30)        // Viền mờ phụ
    readonly property color glassBevelInner: Qt.rgba(0.0, 0.0, 0.0, 0.08)          // Đổ bóng lồi mép kính 3D
    readonly property color glassGleamWhite: Qt.rgba(1.0, 1.0, 1.0, 0.55)          // Vệt sáng lóa bề mặt (Specular Gleam)

    // --- Sapphire Blue Theme Accents ---
    readonly property color accentSapphire: "#0066FF"
    readonly property color accentSapphireHover: "#1A75FF"
    readonly property color accentSapphireGradientEnd: "#0284C7"

    // --- High-Contrast Typography ---
    readonly property color textOnLightPod: "#0F172A"       // Đen tuyền Obsidian cho câu gốc và câu dịch trên nền trắng
    readonly property color textOnLightPodMuted: "#334155"  // Đen Slate cho thông số phụ trên nền trắng
    readonly property color textPrimaryGlass: "#FFFFFF"     // Trắng tinh khiết trên nền Sapphire
    readonly property color textSecondaryGlass: "#94A3B8"
    readonly property color textMutedGlass: "#64748B"

    // --- Vibrant Badges & Accents ---
    readonly property color badgeEmeraldBg: "#DCFCE7"
    readonly property color badgeEmeraldText: "#15803D"
    readonly property color badgeAmberBg: "#FEF3C7"
    readonly property color badgeAmberText: "#B45309"
    readonly property color badgePurpleGradientStart: "#8B5CF6"
    readonly property color badgePurpleGradientEnd: "#EC4899"
    readonly property color accentOrangeKeyword: "#EA580C"

    // --- Dimension & Corner Radius Metrics ---
    readonly property int radiusIsland: 26
    readonly property int radiusPill: 22
    readonly property int islandSpacing: 12
    readonly property int windowPadding: 14

    // --- Existing Accents ---
    readonly property color accentPurple: "#8B5CF6"
    readonly property color accentPink: "#EC4899"
    readonly property color accentCyan: "#38BDF8"
    readonly property color success: "#34D399"
    readonly property color warning: "#FBBF24"
    readonly property color danger: "#F43F5E"

    // --- Existing Text ---
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

    // --- Micro-interaction Tokens (T12) ---
    readonly property int animHover: 120
    readonly property int animFocus: 150
    readonly property int animState: 150
    readonly property int animProgress: 220
}
