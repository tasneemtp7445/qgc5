import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.MultiVehicleManager


Rectangle {
    id: root

    color: "#303030"
    radius: 10

    property var vehicle: QGroundControl.multiVehicleManager.activeVehicle

    width: 170
    height: 170

    function panLeft() {
        if (vehicle)
            vehicle.sendGimbalCommand(-10,0)
    }

    function panRight() {
        if (vehicle)
            vehicle.sendGimbalCommand(10,0)
    }

    function tiltUp() {
        if (vehicle)
            vehicle.sendGimbalCommand(0,-10)
    }

    function tiltDown() {
        if (vehicle)
            vehicle.sendGimbalCommand(0,10)
    }

    GridLayout {
        anchors.fill: parent
        anchors.margins: 15

        rows: 3
        columns: 3

        Button {
            text: ""
            enabled: false
        }

        Button {
    text: "▲"

    onPressed: {
        if (vehicle)
            vehicle.sendGimbalCommand(0, -10)
    }

    onReleased: {
        if (vehicle)
            vehicle.sendGimbalCommand(0, 0)
    }
}

        Button {
            text: ""
            enabled: false
        }

        Button {
    text: "◀"

    onPressed: {
        if (vehicle)
            vehicle.sendGimbalCommand(-10, 0)
    }

    onReleased: {
        if (vehicle)
            vehicle.sendGimbalCommand(0, 0)
    }
}

        Rectangle {
            color: "transparent"

            Label {
                anchors.centerIn: parent
                text: "Gimbal"
                color: "white"
            }
        }

        Button {
    text: "▶"

    onPressed: {
        if (vehicle)
            vehicle.sendGimbalCommand(10, 0)
    }

    onReleased: {
        if (vehicle)
            vehicle.sendGimbalCommand(0, 0)
    }
}

        Button {
            text: ""
            enabled: false
        }

        Button {
    text: "▼"

    onPressed: {
        if (vehicle)
            vehicle.sendGimbalCommand(0, 10)
    }

    onReleased: {
        if (vehicle)
            vehicle.sendGimbalCommand(0, 0)
    }
}

        Button {
            text: ""
            enabled: false
        }
    }
}
