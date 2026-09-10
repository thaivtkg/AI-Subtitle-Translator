import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import "../theme"

Item {
    id: root

    property bool dismissed: false
    readonly property var presets: [
        { label: "1024×600", width: 1024, height: 600 },
        { label: "1280×720", width: 1280, height: 720 },
        { label: "1366×768", width: 1366, height: 768 },
        { label: "1600×900", width: 1600, height: 900 },
        { label: "1920×1080", width: 1920, height: 1080 }
    ]

    visible: !dismissed && Window.window !== null && Qt.application.arguments.indexOf("--dev-tools") >= 0
    implicitWidth: 260
    implicitHeight: 42
    z: 1000

    function applyPreset(index) {
        const preset = root.presets[index]
        if (!preset || !Window.window) return

        if (Window.window.visibility === Window.Maximized)
            Window.window.showNormal()

        Window.window.width = preset.width
        Window.window.height = preset.height

        if (Screen.width > 0 && Screen.height > 0) {
            Window.window.x = Math.max(0, Math.round((Screen.width - preset.width) / 2))
            Window.window.y = Math.max(0, Math.round((Screen.height - preset.height) / 2))
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bgSurfaceElevated
        border.color: Theme.border
        radius: Theme.radius

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spaceSmall
            anchors.rightMargin: Theme.spaceSmall
            spacing: Theme.spaceSmall

            Text {
                text: Window.window
                      ? "Viewport: " + Math.round(Window.window.width) + " × " + Math.round(Window.window.height)
                      : "Viewport: —"
                color: Theme.textSecondary
                font.family: "Segoe UI"
                font.pixelSize: 12
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            ComboBox {
                id: presetSelector
                model: root.presets.map(function(preset) { return preset.label })
                Layout.preferredWidth: 105
                Layout.minimumWidth: 105
                onActivated: root.applyPreset(currentIndex)
            }

            Button {
                text: "×"
                implicitWidth: 28
                implicitHeight: 28
                onClicked: root.dismissed = true
            }
        }
    }
}
