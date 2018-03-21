import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.4

Page {

    id: page

    Column
    {
        anchors.fill: parent
        spacing: Theme.paddingMedium
        Button
        {
            text: "CarNet get VSR"
            width: parent.width
            onClicked:
            {
                python.fncCarNet("retrieveGETVSR");
            }
        }
        Label
        {
            id: idLBLBatteryStatus
        }
        Label
        {
            id: idLBLLockStatus
        }
        Image
        {
            id: idIMGCarImage
        }
    }

    Python
    {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('.'));           

            setHandler('PrintMessageText', function(sMessageText) {
                console.log(sMessageText);
            });

            setHandler('ReturnJSON', function(sJSONText)
            {
                var json=JSON.parse(sJSONText);

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
            });


            importModule('carnet_comm', function () {});

        }       

        function fncCarNet(sCommand)
        {
            call('carnet_comm.fncCarNet', [sCommand], function() {});
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


