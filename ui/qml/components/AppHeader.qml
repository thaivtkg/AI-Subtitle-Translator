import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import "../theme"

ToolBar {
    id: root
    property string projectName: "Untitled"
    property bool isSaved: true

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
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onPressed: Window.window.startSystemMove()
        }
    }

    contentItem: RowLayout {
        spacing: 0

        RowLayout {
            Layout.leftMargin: Theme.spaceMedium
            Text {
                text: "◈ AI Subtitle Translator"
                color: Theme.textSecondary
                font.pixelSize: 14
                font.bold: true
            }
        }

        Item { Layout.fillWidth: true }

        RowLayout {
            spacing: Theme.spaceSmall
            Layout.alignment: Qt.AlignHCenter

            Text {
                text: root.projectName
                color: Theme.textPrimary
                font.pixelSize: 16
                font.bold: true
            }

            Rectangle {
                implicitWidth: statusText.implicitWidth + Theme.spaceMedium
                implicitHeight: 22
                radius: 11
                color: root.isSaved ? Theme.bgSurfaceElevated : Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.15)
                border.color: root.isSaved ? Theme.border : Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.3)
                border.width: 1

                Text {
                    id: statusText
                    anchors.centerIn: parent
                    text: root.isSaved ? "✓ Saved" : "● Unsaved"
                    color: root.isSaved ? Theme.textSecondary : Theme.warning
                    font.pixelSize: 12
                    font.bold: true
                }
            }
        }

        Item { Layout.fillWidth: true }

        RowLayout {
            spacing: 0
            Layout.alignment: Qt.AlignRight

            RowLayout {
                spacing: Theme.spaceSmall
                Layout.rightMargin: Theme.spaceMedium

                AppButton { text: "Open SRT"; onClicked: root.openSrtClicked() }
                AppButton { text: "Open Project"; onClicked: root.openProjectClicked() }
                AppButton { text: "Save"; onClicked: root.saveClicked() }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 16
                    color: Theme.border
                    Layout.margins: Theme.spaceXs
                }

                AppButton { text: "Export SRT"; isPrimary: true; onClicked: root.exportClicked() }
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
