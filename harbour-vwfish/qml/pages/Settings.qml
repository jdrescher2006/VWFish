import QtQuick 2.0
import Sailfish.Silica 1.0

Page
{
    id: page

    property bool bLockOnCompleted : false
    property bool bLockFirstPageLoad: true

    onStatusChanged:
    {
        //This is loaded only the first time the page is displayed
        if (status === PageStatus.Active && bLockFirstPageLoad)
        {
            bLockOnCompleted = true;

            bLockFirstPageLoad = false;
            console.log("First Active SettingsPage");




            bLockOnCompleted = false;
        }

        //This is loaded everytime the page is displayed
        if (status === PageStatus.Active)
        {
            console.log("Active SettingsPage");
        }

        if (status === PageStatus.Inactive)
        {
            console.log("Inactive SettingsPage");

            //Save settings
            settingsConf.user = idTXTuser.text;
            settingsConf.password = idTXTpassword.text;
        }
    }

    SilicaFlickable
    {
        anchors.fill: parent
        contentHeight: mainColumn.height

        VerticalScrollDecorator{}
        Column
        {
            width: parent.width
            id: mainColumn
            PageHeader { title: qsTr("Settings") }

            Column
            {
                width: parent.width
                spacing: Theme.paddingMedium

                TextField
                {
                    id: idTXTuser
                    width: parent.width
                    text: settingsConf.user
                    label: qsTr("Username")
                    placeholderText: qsTr("Username")
                    inputMethodHints: Qt.ImhNoPredictiveText
                }
                TextField
                {
                    id: idTXTpassword
                    width: parent.width
                    text: settingsConf.password
                    label: qsTr("Password")
                    placeholderText: qsTr("Password")
                    inputMethodHints: Qt.ImhNoPredictiveText
                }
            }
        }
    }
}
