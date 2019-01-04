import QtQuick 2.0
import QtQuick.LocalStorage 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.4

Page
{
    id: page
    allowedOrientations: Orientation.All

    property int iLoginStep: 0
    property string sLoginText: ""
    property int iRequestStep: 0
    property string sRequestStepText: ""
    property bool bLockOnCompleted : false
    property bool bLockFirstPageLoad: true
    property bool bHaveFirstData: false
    property int iFullRequestStateMachine: 0
    property string sNextCommand: ""

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

            sNextCommand = "retrieveCarNetInfo";
            python.fncCarNetLogin(settingsConf.user,settingsConf.password);

            bLockOnCompleted = false;
        }

        //This is loaded everytime the page is displayed
        if (status === PageStatus.Active)
        {
            console.log("Active MainPage");            
        }
    }

    Timer
    {
        id: idTimerRequestSequenceEnd
        running: iRequestStep === 7
        repeat: false
        interval: 1000
        onTriggered:
        {
            sRequestStepText = "";
            iRequestStep = 0;
        }
    }

    Timer
    {
        id: idTimerFullRequest
        running: iFullRequestStateMachine > 0
        repeat: false
        interval: 30000
        onTriggered:
        {
            python.fncCarNet("retrieveCarNetInfo");
            iFullRequestStateMachine = 0;
        }
    }

    Timer
    {
        id: idTimerMainRequest
        running: false
        repeat: false
        interval: 600000
        onTriggered:
        {
            console.log("Out of login timer triggered. Next action must be preceded by a login!");
            //Set login bit to false
            bGlobalLogin = false;
        }
    }

    SilicaFlickable
    {
        anchors.fill: parent

        VerticalScrollDecorator {}

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
                text: qsTr("Get car full request")
                onClicked:
                {
                    python.fncCarNet("getCarDataUpdate");
                    iFullRequestStateMachine = 1;
                }
            }
            MenuItem
            {
                text: qsTr("Get car data")
                onClicked:
                {
                    python.fncCarNet("retrieveCarNetInfo");
                }
            }            
        }
        PushUpMenu
        {
            MenuItem
            {
                text: qsTr("Start Climatisation")
                onClicked:
                {                    
                    python.fncCarNet("startClimat");
                }
            }
            MenuItem
            {
                text: qsTr("Start Windowmelt")
                onClicked:
                {
                    python.fncCarNet("startWindowMelt");
                }
            }
            MenuItem
            {
                text: qsTr("Stop Climatisation")
                onClicked:
                {
                    python.fncCarNet("stopClimat");
                }
            }
            MenuItem
            {
                text: qsTr("Stop Windowmelt")
                onClicked:
                {
                    python.fncCarNet("stopWindowMelt");
                }
            }
        }

        Item
        {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.paddingLarge
            width: parent.width
            height: parent.height / 10
            z: 3

            Label
            {
                text: (bGlobalLogin) ? qsTr("Logged in") : qsTr("Logged off")
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: idIMGLogin.right
                anchors.leftMargin: Theme.paddingSmall
            }
            Image
            {
                id: idIMGLogin
                source: (bGlobalLogin) ? "image://theme/icon-m-device-lock" : "../img/icon-m-device-unlock.png"
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                height: parent.height
                width: parent.height
                smooth: true
            }
        }

        Item
        {
            anchors.centerIn: parent
            width: (page.orientation === Orientation.Portrait || page.orientation === Orientation.PortraitInverted || page.orientation === Orientation.PortraitMask) ? parent.width : parent.width / 2
            height: idLabelLogin.height + Theme.paddingLarge + Theme.paddingLarge + progressBarWaitLoadGPX.height + Theme.paddingLarge
            visible: iLoginStep > 0
            z: 3

            Label
            {
                id: idLabelLogin
                width: parent.width
                text: qsTr("Login...")
                color: Theme.primaryColor
                font.pixelSize: Theme.fontSizeLarge
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingLarge
            }
            ProgressBar
            {
                id: progressBarWaitLoadGPX
                width: parent.width
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.paddingLarge
                maximumValue: 10
                valueText: value + " " + qsTr("of") + " 10"
                label: sLoginText
                value: iLoginStep
            }
        }
        Item
        {
            anchors.centerIn: parent
            width: (page.orientation === Orientation.Portrait || page.orientation === Orientation.PortraitInverted || page.orientation === Orientation.PortraitMask) ? parent.width : parent.width / 2
            height: idLabelRequestSequence.height + Theme.paddingLarge + Theme.paddingLarge + progressBarWaitRequestSequence.height + Theme.paddingLarge
            visible: iRequestStep > 0
            z: 4

            Label
            {
                id: idLabelRequestSequence
                width: parent.width
                text: qsTr("Requesting server...")
                color: Theme.primaryColor
                font.pixelSize: Theme.fontSizeLarge
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingLarge
            }
            ProgressBar
            {
                id: progressBarWaitRequestSequence
                width: parent.width
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.paddingLarge
                maximumValue: 7
                valueText: value + " " + qsTr("of") + " 7"
                label: sRequestStepText
                value: iRequestStep
            }
        }

        Column
        {
            anchors.fill: parent
            spacing: Theme.paddingMedium
            visible: iRequestStep === 0

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

            setHandler('ReturnLoginURL', function(sLoginURL, oSessionObject)
            {
                console.log("sLoginURL: " + sLoginURL);
                sGlobalVarLoginURL = sLoginURL;
                oGlobalSessionObject = oSessionObject;
                bGlobalLogin = true;                                              

                //Start login timer, because login does not last for ever!
                idTimerMainRequest.running = true;

                //Check if a command is in the que
                if (sNextCommand !== "")
                {
                    python.fncCarNet(sNextCommand);
                }
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

                if (sCommand === "get-new-messages")
                {
                    iRequestStep = 1;
                    sRequestStepText = "get-new-messages";
                }
                if (sCommand === "get-vsr")
                {
                    iRequestStep = 2;
                    sRequestStepText = "get-vsr";
                }
                if (sCommand === "get-location")
                {
                    iRequestStep = 3;
                    sRequestStepText = "get-location";
                }
                if (sCommand === "get-vehicle-details")
                {
                    iRequestStep = 4;
                    sRequestStepText = "get-vehicle-details";
                }
                if (sCommand === "get-emanager")
                {
                    iRequestStep = 5;
                    sRequestStepText = "get-emanager";
                }
                if (sCommand === "get-fully-loaded-cars")
                {
                    iRequestStep = 6;
                    sRequestStepText = "get-fully-loaded-cars";
                }
                if (sCommand === "get-last-refuel-trip-statistics")
                {
                    iRequestStep = 7;
                    sRequestStepText = "get-last-refuel-trip-statistics";

                    //This is the last command of the request sequence.
                    var sErrorCode = json.errorCode;
                    if (sErrorCode === "0")
                    {
                        fncShowMessage(2,qsTr("Get car data successful!"), 2000);
                    }
                    else
                    {
                        fncShowMessage(3,qsTr("Request error: " + sErrorCode), 2000);
                    }
                }


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

                        //Get current
                        var iMaxCurrent = parseInt(json.EManager.rbc.settings.chargerMaxCurrent);
                        idLBLChargeStatus.text = idLBLChargeStatus.text + "\r\n" + qsTr("Current: " + iMaxCurrent.toString() + "A");
                    }
                    else
                    {
                        idLBLChargeStatus.text = qsTr("Not charging");
                    }

                    //Clima
                    iClimaStatus = !(json.EManager.rpc.status.climatisationState === "OFF") ? 1 : 0;
                    var iClimatisationRemaningTime = json.EManager.rpc.status.climatisationRemaningTime;
                    var iWindowHeatingStateFront = !(json.EManager.rpc.status.windowHeatingStateFront === "OFF") ? 1 : 0;

                    idLBLClimaStatus.text = qsTr("Climatisation: ") + ((iClimaStatus === 0) ? qsTr("OFF") : qsTr("ON")) + qsTr(", remaining time: ") + iClimatisationRemaningTime;
                    idLBLClimaStatus.text = idLBLClimaStatus.text + "\r\n" + qsTr("Front window heating: ") + ((iWindowHeatingStateFront === 0) ? qsTr("OFF") : qsTr("ON"));
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
                        fncShowMessage(2,qsTr("Car request successful!"), 2000);
                    }
                    else
                    {
                        fncShowMessage(3,qsTr("Request error: " + sErrorCode), 6000);
                    }
                }
                if (sCommand === "trigger-climatisation-start")
                {
                    if (json.errorCode === "0" && json.actionNotification.actionType === "START_CLIMATISATION" && json.actionNotification.errorMessage === null)
                    {
                        fncShowMessage(2,qsTr("Climatisation started!"), 2000);
                    }
                    else
                    {
                        fncShowMessage(3,qsTr("Request error! Error code: " + json.errorCode + "\r\nerror title: " + json.actionNotification.errorTitle + "\r\nerror message: " + json.actionNotification.errorMessage), 20000);
                    }
                }
                if (sCommand === "trigger-climatisation-stop")
                {
                    if (json.errorCode === "0" && json.actionNotification.actionType === "STOP_CLIMATISATION" && json.actionNotification.errorMessage === null)
                    {
                        fncShowMessage(2,qsTr("Climatisation stopped!"), 2000);
                    }
                    else
                    {
                        fncShowMessage(3,qsTr("Request error! Error code: " + json.errorCode + "\r\nerror title: " + json.actionNotification.errorTitle + "\r\nerror message: " + json.actionNotification.errorMessage), 20000);
                    }
                }

                if (sCommand === "trigger-windowheating-start")
                {
                    if (json.errorCode === "0" && json.actionNotification.actionType === "START_CLIMATISATION" && json.actionNotification.errorMessage === null)
                    {
                        fncShowMessage(2,qsTr("Window heating started!"), 2000);
                    }
                    else
                    {
                        fncShowMessage(3,qsTr("Request error! Error code: " + json.errorCode + "\r\nerror title: " + json.actionNotification.errorTitle + "\r\nerror message: " + json.actionNotification.errorMessage), 20000);
                    }
                }
                if (sCommand === "trigger-windowheating-stop")
                {
                    if (json.errorCode === "0" && json.actionNotification.actionType === "STOP_CLIMATISATION" && json.actionNotification.errorMessage === null)
                    {
                        fncShowMessage(2,qsTr("Window heating stopped!"), 2000);
                    }
                    else
                    {
                        fncShowMessage(3,qsTr("Request error! Error code: " + json.errorCode + "\r\nerror title: " + json.actionNotification.errorTitle + "\r\nerror message: " + json.actionNotification.errorMessage), 20000);
                    }
                }

                if (sCommand === "charge-battery-start")
                {
                    if (json.errorCode === "0" && json.actionNotification.actionType === "START_CLIMATISATION" && json.actionNotification.errorMessage === null)
                    {
                        fncShowMessage(2,qsTr("Charging battery started!"), 2000);
                    }
                    else
                    {
                        fncShowMessage(3,qsTr("Request error! Error code: " + json.errorCode + "\r\nerror title: " + json.actionNotification.errorTitle + "\r\nerror message: " + json.actionNotification.errorMessage), 20000);
                    }
                }
                if (sCommand === "charge-battery-stop")
                {
                    if (json.errorCode === "0" && json.actionNotification.actionType === "STOP_CLIMATISATION" && json.actionNotification.errorMessage === null)
                    {
                        fncShowMessage(2,qsTr("Charging battery stopped!"), 2000);
                    }
                    else
                    {
                        fncShowMessage(3,qsTr("Request error! Error code: " + json.errorCode + "\r\nerror title: " + json.actionNotification.errorTitle + "\r\nerror message: " + json.actionNotification.errorMessage), 20000);
                    }
                }
            });


            importModule('carnet_comm', function () {});

        }       

        function fncCarNetLogin(sUsername, sPassword)
        {
            call('carnet_comm.fncCarNetLogin', [sUsername, sPassword], function() {});
        }


        function fncCarNet(sCommand)
        {
            call('carnet_comm.fncCarNet', [sCommand, sGlobalVarLoginURL, oGlobalSessionObject], function() {});
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


