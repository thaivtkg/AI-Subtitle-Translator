import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

Rectangle {
    color: "transparent"
    
    ColumnLayout {
        anchors.centerIn: parent
        spacing: Theme.spaceLarge
        
        Text {
            text: "◈"
            color: Theme.accentSecondary
            font.pixelSize: 48
            Layout.alignment: Qt.AlignHCenter
        }
        
        ColumnLayout {
            spacing: Theme.spaceSmall
            Layout.alignment: Qt.AlignHCenter
            
            Text {
                text: "Start translating subtitles"
                color: Theme.textPrimary
                font.family: Theme.fontUI
                font.pixelSize: 24
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
            
            Text {
                text: "Import an SRT or existing project to get started."
                color: Theme.textSecondary
                font.family: Theme.fontUI
                font.pixelSize: Theme.fontSizeBody
                Layout.alignment: Qt.AlignHCenter
            }
        }
        
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spaceMedium
            Layout.topMargin: Theme.spaceMedium
            
            AppButton { 
                text: "Open SRT"
                onClicked: importSrtDialog.open()
            }
            AppButton { 
                text: "Open Project"
                isPrimary: true
                onClicked: loadProjectDialog.open()
            }
        }
    }
}