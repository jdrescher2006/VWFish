import QtQuick 2.0
import QtQuick.LocalStorage 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.4

Page {

    id: page
    property int iLoginStep: 0
    property string sLoginText: ""
    property bool bLockOnCompleted : false
    property bool bLockFirstPageLoad: true

    onStatusChanged:
    {
        //This is loaded only the first time the page is displayed
        if (status === PageStatus.Active && bLockFirstPageLoad)
        {
            bLockOnCompleted = true;

            bLockFirstPageLoad = false;
            console.log("First Active MainPage");

            bLockOnCompleted = false;
        }

        //This is loaded everytime the page is displayed
        if (status === PageStatus.Active)
        {
            console.log("Active MainPage");
        }
    }

    SilicaFlickable
    {
        anchors.fill: parent

        PullDownMenu
        {
            id: menu            
            MenuItem
            {
                text: qsTr("Settings")
                onClicked:
                {
                    pageStack.push(Qt.resolvedUrl("Settings.qml"))
                }
            }
            MenuItem
            {
                text: qsTr("Request car info")
                onClicked:
                {
                    python.fncCarNet("getCarDataUpdate", settingsConf.user,settingsConf.password);
                }
            }
        }
        Column
        {
            anchors.fill: parent
            spacing: Theme.paddingMedium

            PageHeader
            {
                title: qsTr("VW Car Net Remote")
            }

            Item
            {
                width: parent.width
                height: Theme.paddingLarge
            }
            Button
            {
                text: "CarNet get Info"
                width: parent.width
                onClicked:
                {
                    python.fncCarNet("retrieveCarNetInfo", settingsConf.user,settingsConf.password);
                }
            }
            Label
            {
                id: idLBLCarInfo
            }
            Label
            {
                id: idLBLLastDateUpdate
            }
            Label
            {
                id: idLBLBatteryStatus
            }
            Label
            {
                id: idLBLChargeStatus
            }
            Label
            {
                id: idLBLLockStatus
            }
            ProgressBar
            {
                id: progressBarWaitLoadGPX
                width: parent.width
                maximumValue: 10
                valueText: value + " " + qsTr("of") + " 10"
                label: sLoginText
                value: iLoginStep
                visible: iLoginStep > 0
            }
        }
    }

    Python
    {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('.'));           

            setHandler('PrintMessageText', function(sMessageText)
            {
                console.log(sMessageText);
            });

            setHandler('ReturnProgress', function(progressStep, sProgressText)
            {
                console.log(progressStep.toString());
                iLoginStep = progressStep;
                sLoginText = sProgressText;
            });

            setHandler('ReturnJSON', function(sJSONText, sCommand)
            {
                var json=JSON.parse(sJSONText);

                console.log("Command: " + sCommand + ", Data: " + sJSONText)

                if (sCommand === "get-vsr")
                {
                    idLBLBatteryStatus.text = "Battery: " + json.vehicleStatusData.batteryLevel + "%, Range: " + json.vehicleStatusData.batteryRange + "km"
                    idLBLLockStatus.text = "Left front: " + json.vehicleStatusData.lockData.left_front +
                            ", right front: " + json.vehicleStatusData.lockData.right_front + "\r\n" +
                            "Left back: " + json.vehicleStatusData.lockData.left_back +
                            ", right back: " + json.vehicleStatusData.lockData.right_back + "\r\n" +
                            "Trunk: " + json.vehicleStatusData.lockData.trunk

                    //idIMGCarImage.source = json.vehicleStatusData.sliceRootPath + "_car@2x.png"

                    //https://www.volkswagen-car-net.com/static/slices/default_car/default_car_car@2x.png - server replied: Not Found
                    //https://www.volkswagen-car-net.com/static/slices/e_up_2017/e_up_2017_car@2x.png
                    //https://www.volkswagen-car-net.com/static/slices/e_up_2017/e_up_2017_door_lr_closed@2x.png
                    //https://media.volkswagen.com/Vilma/V/BL2/2018/Front_Right/91a9ed1f7e0334e7b95bcbe4f89a0eaffa08fcd61313454887ab4ad4c17b9a50.png?width=640
                }
                if (sCommand === "get-vehicle-details")
                {
                       idLBLLastDateUpdate.text = "Last car infos: " + json.vehicleDetails.lastConnectionTimeStamp.toString();
                }
                if (sCommand === "get-emanager")
                {
                       idLBLChargeStatus.text = "hours: " + json.EManager.rbc.status.chargingRemaningHour + ", minutes: " + json.EManager.rbc.status.chargingRemaningMinute
                }
                if (sCommand === "get-fully-loaded-cars")
                {
                    idLBLCarInfo.text = json.fullyLoadedVehiclesResponse.vehiclesNotFullyLoaded[0].name + " " + json.fullyLoadedVehiclesResponse.vehiclesNotFullyLoaded[0].vin;
                }
                if (sCommand === "request-vsr")
                {
                    var sErrorCode = json.errorCode;
                    if (sErrorCode === "0")
                    {
                        fncShowMessage(2,qsTr("Request successful!"), 2000);
                    }
                    else
                    {
                        fncShowMessage(3,qsTr("Request error: " + sErrorCode), 2000);
                    }
                }
            });


            importModule('carnet_comm', function () {});

        }       

        function fncCarNet(sCommand, sUsername, sPassword)
        {
            call('carnet_comm.fncCarNet', [sCommand, sUsername, sPassword], function() {});
        }

        onError: {
            // when an exception is raised, this error handler will be called
            console.log('python error: ' + traceback);
        }

        onReceived: {
            // asychronous messages from Python arrive here
            // in Python, this can be accomplished via pyotherside.send()
            console.log('got message from python: ' + data);
        }
    }
}


