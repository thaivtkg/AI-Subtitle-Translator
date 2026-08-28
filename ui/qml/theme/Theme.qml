pragma Singleton
import QtQuick 2.15

QtObject {
    readonly property color bgApp: "#0E1116"
    readonly property color bgSurface: "#161B22"
    readonly property color bgSurfaceElevated: "#21262D"
    readonly property color bgSurfaceSoft: "#30363D"
    readonly property color border: "#30363D"
    readonly property color borderFocus: "#58A6FF"

    readonly property color accentPrimary: "#238636"
    readonly property color accentSecondary: "#58A6FF"
    readonly property color accentMuted: "#1F6FEB"
    readonly property color warning: "#D29922"
    readonly property color danger: "#F85149"

    readonly property string fontUI: "Segoe UI"

    readonly property int fontApp: 15      // Logo / App Title
    readonly property int fontSection: 14  // Header các Panel
    readonly property int fontBody: 13     // Nội dung chính
    readonly property int fontLabel: 12    // Nút bấm, Meta data
    readonly property int fontCaption: 11  // Badge, Status nhỏ

    // --- Spacing System (4-point grid) ---
    readonly property int space4: 4
    readonly property int space8: 8
    readonly property int space12: 12
    readonly property int space16: 16
    readonly property int space24: 24
    
    readonly property color textPrimary: "#C9D1D9"
    readonly property color textSecondary: "#9CA3AF"
    readonly property color textMuted: "#6B7280"
    
    // --- BỔ SUNG BIẾN BỊ THIẾU ĐỂ SỬA LỖI ---
    readonly property color textDisabled: "#6E7681" 
    
    readonly property int fontSizeTitle: 15
    readonly property int fontSizeBody: 13
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeBadge: 10

    readonly property int spaceXs: 4
    readonly property int spaceSmall: 8
    readonly property int spaceMedium: 16
    readonly property int spaceLarge: 24
    
    readonly property int radius: 4
    readonly property int animDuration: 120
}