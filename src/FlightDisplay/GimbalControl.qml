import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QGroundControl
import QGroundControl.MultiVehicleManager

Rectangle {
    id: gimbalControl

    property var activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    anchors.fill: parent
    color: "#252525"
    

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 25
        spacing: 20

        // =========================================================
        // TITLE
        // =========================================================

        Label {
            text: "Gimbal Control"
            font.pixelSize: 28
            color: "white"
            Layout.alignment: Qt.AlignHCenter
        }

        // =========================================================
        // MAIN GIMBAL CONTROL PANEL
        // =========================================================

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: 10
            color: "#303030"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 25
                spacing: 50

                // =================================================
                // LEFT SIDE - PAN / TILT
                // =================================================

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter

                    spacing: 20

                    Label {
                        text: "Pan"
                        color: "white"
                        font.pixelSize: 20
                    }

                    Row {
                        spacing: 15

                       Button {
    text: "◀"

    onClicked: {
        if (activeVehicle)
            activeVehicle.gimbalPan(-10)
    }
}

                        Button {
    text: "▶"

    onClicked: {
        if (activeVehicle)
            activeVehicle.gimbalPan(10)
    }
}
                    }

                    Label {
                        text: "Tilt"
                        color: "white"
                        font.pixelSize: 20
                    }

                   Button {
    text: "▲"
    width: 70

    onClicked: {
        if (activeVehicle)
            activeVehicle.gimbalTilt(10)
    }
}

                   Button {
    text: "▼"
    width: 70

    onClicked: {
        if (activeVehicle)
            activeVehicle.gimbalTilt(-10)
    }
}
                }

                // =================================================
                // CENTER - JOYSTICK
                // =================================================

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter

                    spacing: 15

                    Label {
                        text: "Joystick"
                        color: "white"
                        font.pixelSize: 20
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Rectangle {
                        id: joystickArea

                        width: 220
                        height: 220

                        radius: width / 2

                        color: "#505050"

                        border.width: 3
                        border.color: "#888888"

                        property real centerX: width / 2
                        property real centerY: height / 2

                        property real maxDistance: (width - joystickKnob.width) / 2

                        property real joystickX: 0
                        property real joystickY: 0

                        // -----------------------------------------
                        // JOYSTICK KNOB
                        // -----------------------------------------

                        Rectangle {
                            id: joystickKnob

                            width: 40
                            height: 40

                            radius: width / 2

                            color: "#00BCD4"

                            x: joystickArea.centerX - width / 2
                            y: joystickArea.centerY - height / 2
                        }

                        // -----------------------------------------
                        // JOYSTICK TOUCH / MOUSE CONTROL
                        // -----------------------------------------

                        MouseArea {
                            anchors.fill: parent

                            onPressed: function(mouse) {
                                joystickArea.updateJoystick(
                                    mouse.x,
                                    mouse.y
                                )
                            }

                            onPositionChanged: function(mouse) {
                                if (pressed) {
                                    joystickArea.updateJoystick(
                                        mouse.x,
                                        mouse.y
                                    )
                                }
                            }

                            onReleased: {
                                joystickArea.resetJoystick()
                            }
                        }

                        // -----------------------------------------
                        // UPDATE JOYSTICK POSITION
                        // -----------------------------------------

                        function updateJoystick(mouseX, mouseY) {

                            var dx = mouseX - centerX
                            var dy = mouseY - centerY

                            var distance =
                                    Math.sqrt(
                                        dx * dx +
                                        dy * dy
                                    )

                            if (distance > maxDistance) {

                                dx =
                                    dx / distance *
                                    maxDistance

                                dy =
                                    dy / distance *
                                    maxDistance
                            }

                            joystickKnob.x =
                                    centerX +
                                    dx -
                                    joystickKnob.width / 2

                            joystickKnob.y =
                                    centerY +
                                    dy -
                                    joystickKnob.height / 2

                            joystickX =
                                    dx / maxDistance

                            joystickY =
                                    dy / maxDistance

                            console.log(
    "Gimbal Joystick:",
    "X =", joystickX,
    "Y =", joystickY
)

if (activeVehicle) {
    activeVehicle.gimbalJoystick(
        joystickX,
        joystickY
    )
}
                        }

                        // -----------------------------------------
                        // RESET JOYSTICK
                        // -----------------------------------------

                        function resetJoystick() {

                            joystickKnob.x =
                                    centerX -
                                    joystickKnob.width / 2

                            joystickKnob.y =
                                    centerY -
                                    joystickKnob.height / 2

                            if (activeVehicle) {
    activeVehicle.gimbalJoystick(0, 0)
}

                            console.log(
                                "Gimbal Joystick released"
                            )
                        }
                    }
                }

                // =================================================
                // RIGHT SIDE - STATUS / ZOOM
                // =================================================

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter

                    spacing: 15

                    Label {
                        text: "Status"
                        color: "white"
                        font.pixelSize: 20
                    }

                    Label {
                        text: "Pitch : 0°"
                        color: "lightgray"
                    }

                    Label {
                        text: "Yaw : 0°"
                        color: "lightgray"
                    }

                    Label {
                        text: "Zoom"
                        color: "white"
                        font.pixelSize: 20
                    }

                    Button {
    text: "+"

    onClicked: {
        if (activeVehicle)
            activeVehicle.gimbalZoom(1)
    }
}

                    Button {
    text: "-"

    onClicked: {
        if (activeVehicle)
            activeVehicle.gimbalZoom(-1)
    }
}
                }
            }
        }

        // =========================================================
        // BOTTOM BUTTONS
        // =========================================================

        RowLayout {
            Layout.alignment: Qt.AlignHCenter

            spacing: 20

            Button {
                text: "Center"
            }

            Button {
                text: "Reset"

                onClicked: {
                    joystickArea.resetJoystick()
                }
            }

            Button {
                text: "Follow"
            }

            Button {
                text: "Lock"
            }
        }
    }
}