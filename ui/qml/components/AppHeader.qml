import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import "../theme"

ToolBar {
    id: root
    property string projectName: "Untitled"
    property bool isSaved: true
    property bool hasProjectData: false
    readonly property bool isCompact: width < 1280
    readonly property bool isMinimum: width < 1100

    signal openSrtClicked()
    signal openProjectClicked()
    signal saveClicked()
    signal exportClicked()

    implicitHeight: 48
    padding: 0

    background: Rectangle {
        color: Theme.bgApp
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: Theme.border
        }
    }

    contentItem: Item {
        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.LeftButton
            onPressed: Window.window.startSystemMove()
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            RowLayout {
                Layout.leftMargin: Theme.spaceMedium
                Text {
                    text: root.isMinimum ? "AI Subtitle Translator" : "◈ AI Subtitle Translator"
                    color: Theme.textSecondary
                    font.pixelSize: 14
                    font.bold: true
                }
            }

            Item {
                Layout.fillWidth: !root.isMinimum
                Layout.minimumWidth: root.isMinimum ? Theme.spaceMedium : 0
            }

            RowLayout {
                spacing: Theme.spaceSmall
                Layout.alignment: root.isMinimum ? Qt.AlignLeft : Qt.AlignHCenter

                Text {
                    text: root.projectName
                    color: Theme.textPrimary
                    font.pixelSize: 16
                    font.bold: true
                }

                Rectangle {
                    implicitWidth: statusText.implicitWidth + (root.isMinimum ? Theme.spaceSmall : Theme.spaceMedium)
                    implicitHeight: 22
                    radius: 11
                    color: root.isSaved ? Theme.bgSurfaceElevated : Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.15)
                    border.color: root.isSaved ? Theme.border : Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.3)
                    border.width: 1

                    Text {
                        id: statusText
                        anchors.centerIn: parent
                        text: root.isSaved ? (root.isMinimum ? "✓" : "✓ Saved") : (root.isMinimum ? "●" : "● Unsaved")
                        color: root.isSaved ? Theme.textSecondary : Theme.warning
                        font.pixelSize: 12
                        font.bold: true
                    }

                    ToolTip.visible: chipMouse.containsMouse
                    ToolTip.text: root.isSaved ? "Project saved" : "Unsaved changes"
                    MouseArea {
                        id: chipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                }
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 0
                Layout.alignment: Qt.AlignRight

                RowLayout {
                    spacing: root.isCompact ? Theme.spaceXs : Theme.spaceSmall
                    Layout.rightMargin: root.isCompact ? Theme.spaceSmall : Theme.spaceMedium

                    AppButton { text: root.isMinimum ? "SRT" : "Open SRT"; tooltip: "Ctrl + O"; onClicked: root.openSrtClicked() }
                    AppButton { text: root.isMinimum ? "Project" : "Open Project"; tooltip: "Ctrl + Shift + O"; onClicked: root.openProjectClicked() }
                    AppButton { text: "Save"; tooltip: "Ctrl + S"; enabled: root.projectName !== "Untitled" && !root.isSaved; onClicked: root.saveClicked() }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 16
                        color: Theme.border
                        Layout.margins: Theme.spaceXs
                    }

                    AppButton { text: root.isMinimum ? "Export" : "Export SRT"; tooltip: "Ctrl + Shift + S"; isPrimary: true; enabled: root.projectName !== "Untitled" && root.hasProjectData; onClicked: root.exportClicked() }
                }

                Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Theme.border }

                RowLayout {
                    spacing: 0
                    Button {
                        implicitWidth: 46; implicitHeight: 48
                        contentItem: Text { text: "—"; color: Theme.textSecondary; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.bold: true }
                        background: Rectangle { color: parent.hovered ? Theme.bgSurfaceSoft : "transparent" }
                        onClicked: Window.window.showMinimized()
                    }
                    Button {
                        implicitWidth: 46; implicitHeight: 48
                        contentItem: Text { text: Window.window.visibility === Window.Maximized ? "🗗" : "🗖"; color: Theme.textSecondary; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: parent.hovered ? Theme.bgSurfaceSoft : "transparent" }
                        onClicked: {
                            if (Window.window.visibility === Window.Maximized) Window.window.showNormal()
                            else Window.window.showMaximized()
                        }
                    }
                    Button {
                        implicitWidth: 46; implicitHeight: 48
                        contentItem: Text { text: "✕"; color: parent.hovered ? "#FFFFFF" : Theme.textSecondary; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: parent.hovered ? Theme.danger : "transparent" }
                        onClicked: Window.window.close()
                    }
                }
            }
        }
    }
}
