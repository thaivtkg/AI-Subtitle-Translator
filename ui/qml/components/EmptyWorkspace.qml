import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Item {
    id: root
    property string emptyStateMode: "no_project"
    signal openSrtClicked()
    signal openProjectClicked()

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.7, 400)
        spacing: Theme.spaceMedium

        Text { Layout.alignment: Qt.AlignHCenter; text: root.emptyStateMode === "no_project" ? "📂" : "🎯"; font.pixelSize: 36 }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.emptyStateMode === "no_project" ? "No project loaded" : "Select a subtitle"
            color: Theme.textPrimary; font.pixelSize: 18; font.bold: true; horizontalAlignment: Text.AlignHCenter
        }
        Text {
            Layout.fillWidth: true; Layout.alignment: Qt.AlignHCenter
            text: root.emptyStateMode === "no_project" ? "Open an SRT file or existing project workspace to start translating subtitles with AI." : "Choose a subtitle item from the navigator on the left to view, edit, or translate it."
            color: Theme.textMuted; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
        }
        RowLayout {
            visible: root.emptyStateMode === "no_project"
            Layout.alignment: Qt.AlignHCenter; Layout.topMargin: Theme.spaceSmall; spacing: Theme.spaceSmall
            AppButton { text: "Open SRT"; isPrimary: true; onClicked: root.openSrtClicked() }
            AppButton { text: "Open Project"; onClicked: root.openProjectClicked() }
        }
    }
}
