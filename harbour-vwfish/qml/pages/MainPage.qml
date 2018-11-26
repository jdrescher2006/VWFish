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
    property bool bHaveFirstData: false

    //Car status variables
    property int iClimaStatus: -1

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
                text: qsTr("Start Climatisation")
                onClicked:
                {
                    python.fncCarNet("startClimat", settingsConf.user,settingsConf.password);
                }
            }
            MenuItem
            {
                text: qsTr("Stop Climatisation")
                onClicked:
                {
                    python.fncCarNet("stopClimat", settingsConf.user,settingsConf.password);
                }
            }
            MenuItem
            {
                text: qsTr("Start Windowmelt")
                onClicked:
                {
                    python.fncCarNet("startWindowMelt", settingsConf.user,settingsConf.password);
                }
            }
            MenuItem
            {
                text: qsTr("Stop Windowmelt")
                onClicked:
                {
                    python.fncCarNet("stopWindowMelt", settingsConf.user,settingsConf.password);
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
            MenuItem
            {
                text: qsTr("CarNet get Info")
                onClicked:
                {
                    python.fncCarNet("retrieveCarNetInfo", settingsConf.user,settingsConf.password);
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
            SectionHeader { text: "Car data"; visible: bHaveFirstData }
            Label
            {
                id: idLBLCarInfo
                x: Theme.paddingLarge
            }
            Label
            {
                id: idLBLLastDateUpdate
                x: Theme.paddingLarge
            }
            SectionHeader { text: "Battery status"; visible: bHaveFirstData }
            Label
            {
                id: idLBLBatteryStatus
                x: Theme.paddingLarge
            }
            SectionHeader { text: "Charge status"; visible: bHaveFirstData }
            Label
            {
                id: idLBLChargeStatus
                x: Theme.paddingLarge
            }
            SectionHeader { text: "Clima status"; visible: bHaveFirstData }
            Label
            {
                id: idLBLClimaStatus
                x: Theme.paddingLarge
            }
            SectionHeader { text: "Lock status"; visible: bHaveFirstData }
            Label
            {
                id: idLBLLockStatus
                x: Theme.paddingLarge
            }
            Separator
            {
                visible: iLoginStep > 0
                color: Theme.highlightColor
                width: parent.width
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

        Component.onCompleted:
        {
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
                    bHaveFirstData = true;

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
                       idLBLLastDateUpdate.text = "Last car infos: " + json.vehicleDetails.lastConnectionTimeStamp[0].toString() + " " + json.vehicleDetails.lastConnectionTimeStamp[1].toString();
                }
                if (sCommand === "get-emanager")
                {
                    var bIsCharging = !(json.EManager.rbc.status.chargingState === "OFF");

                    if (bIsCharging)
                    {
                        var iHours =  parseInt(json.EManager.rbc.status.chargingRemaningHour);
                        var iMinutes = parseInt(json.EManager.rbc.status.chargingRemaningMinute);

                        idLBLChargeStatus.text = iHours === 0 ? qsTr("Remaining time: ") + iMinutes.toString() + " minutes" : qsTr("Remaining time: ") + iHours.toString() + " hours and " + iMinutes.toString() + " minutes";

                        var currentTime = new Date();
                        currentTime.setHours(currentTime.getHours() + iHours, currentTime.getMinutes() + iMinutes);

                        idLBLChargeStatus.text = idLBLChargeStatus.text + "\r\n" + qsTr("Charge end: ") + currentTime.getDate().toString() + "." + (currentTime.getMonth() + 1).toString() + "." + currentTime.getFullYear().toString() + " " + fncPadZeros(currentTime.getHours(), 2).toString() + ":" + fncPadZeros(currentTime.getMinutes(),2).toString();
                    }
                    else
                    {
                        idLBLChargeStatus.text = qsTr("Not charging");
                    }

                    //Clima
                    iClimaStatus = !(json.EManager.rpc.status.climatisationState === "OFF") ? 1 : 0;
                    idLBLClimaStatus.text = (iClimaStatus === 0) ? qsTr("OFF") : qsTr("ON");
                }
                if (sCommand === "get-fully-loaded-cars")
                {
                    idLBLCarInfo.text = "VW " + json.fullyLoadedVehiclesResponse.vehiclesNotFullyLoaded[0].name + " " + json.fullyLoadedVehiclesResponse.vehiclesNotFullyLoaded[0].vin;
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

        function fncPadZeros(number, size)
        {
          number = number.toString();
          while (number.length < size) number = "0" + number;
          return number;
        }
    }
}


