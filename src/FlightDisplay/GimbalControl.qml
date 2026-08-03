import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.MultiVehicleManager

Rectangle {
    id: root

    width: 300
    height: 300
    radius: 28

    color: "#B0000000"
    border.color: "#40ffffff"
    border.width: 1

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property int commandSpeed: 10
    property bool stickPressed: false


    function moveGimbal(pan, tilt) {
        if (_activeVehicle)
            _activeVehicle.sendGimbalCommand(pan, tilt)
    }


    function stopGimbal() {
        moveGimbal(0, 0)
    }


    function panLeft() {
        moveGimbal(-commandSpeed, 0)
    }


    function panRight() {
        moveGimbal(commandSpeed, 0)
    }


    function tiltUp() {
        moveGimbal(0, commandSpeed)
    }


    function tiltDown() {
        moveGimbal(0, -commandSpeed)
    }



    // UP BUTTON
    RoundButton {

        id: tiltUpButton

        width: 68
        height: 68

        text: "▲"

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 18


        onPressed: root.tiltUp()

        onReleased: root.stopGimbal()


        background: Rectangle {

            radius: width / 2

            color: tiltUpButton.pressed
                   ? "#00AEEF"
                   : "#E8E8E8"


            border.color: "white"
            border.width: 2
        }
    }



    // LEFT BUTTON
    RoundButton {

        id: panLeftButton

        width: 68
        height: 68

        text: "◀"


        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.verticalCenter: parent.verticalCenter


        onPressed: root.panLeft()

        onReleased: root.stopGimbal()


        background: Rectangle {

            radius: width / 2

            color: panLeftButton.pressed
                   ? "#00AEEF"
                   : "#E8E8E8"


            border.color: "white"
            border.width: 2
        }
    }



    // RIGHT BUTTON
    RoundButton {

        id: panRightButton

        width: 68
        height: 68

        text: "▶"


        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter


        onPressed: root.panRight()

        onReleased: root.stopGimbal()


        background: Rectangle {

            radius: width / 2

            color: panRightButton.pressed
                   ? "#00AEEF"
                   : "#E8E8E8"


            border.color: "white"
            border.width: 2
        }
    }



    // DOWN BUTTON
    RoundButton {

        id: tiltDownButton

        width: 68
        height: 68

        text: "▼"


        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18


        onPressed: root.tiltDown()

        onReleased: root.stopGimbal()


        background: Rectangle {

            radius: width / 2

            color: tiltDownButton.pressed
                   ? "#00AEEF"
                   : "#E8E8E8"


            border.color: "white"
            border.width: 2
        }
    }




    // JOYSTICK AREA
    Rectangle {

        id: outerRing

        width: 145
        height: 145

        radius: width / 2

        anchors.centerIn: parent


        color: "#22000000"

        border.color: "#70ffffff"
        border.width: 2



        Rectangle {

            id: stick

            width: 68
            height: 68

            radius: width / 2


            x: (outerRing.width-width)/2
            y: (outerRing.height-height)/2


            color: root.stickPressed
                   ? "#00AEEF"
                   : "#484848"


            border.color: "#A0A0A0"
            border.width: 2


            Behavior on x {

                NumberAnimation {

                    duration: 100
                }
            }


            Behavior on y {

                NumberAnimation {

                    duration: 100
                }
            }
        }



        MouseArea {

            anchors.fill: parent



            function updateJoystick(mouseX, mouseY)
            {

                var centerX = outerRing.width/2

                var centerY = outerRing.height/2


                var maxDistance =
                (outerRing.width-stick.width)/2



                var dx = mouseX-centerX

                var dy = mouseY-centerY



                var distance =
                Math.sqrt(dx*dx+dy*dy)



                if(distance > maxDistance)
                {
                    dx = dx*maxDistance/distance

                    dy = dy*maxDistance/distance
                }



                stick.x =
                centerX+dx-stick.width/2


                stick.y =
                centerY+dy-stick.height/2



                var pan =
                Math.round(dx/maxDistance *
                root.commandSpeed)



                var tilt =
                Math.round(-dy/maxDistance *
                root.commandSpeed)



                root.moveGimbal(pan,tilt)
            }



            onPressed:
            {
                root.stickPressed = true

                updateJoystick(mouse.x,mouse.y)
            }



            onPositionChanged:
            {
                if(pressed)
                    updateJoystick(mouse.x,mouse.y)
            }



            onReleased:
            {
                root.stickPressed=false


                stick.x =
                (outerRing.width-stick.width)/2


                stick.y =
                (outerRing.height-stick.height)/2


                root.stopGimbal()
            }
        }
    }
}