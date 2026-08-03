import QtQuick

Item {
    id: root

    Image {
        anchors.fill: parent
        source: "../Images/CompassModern/shadow.svg"
        fillMode: Image.PreserveAspectFit
    }

    Image {
        anchors.fill: parent
        source: "../Images/CompassModern/bezel.svg"
        fillMode: Image.PreserveAspectFit
    }

    Image {
        anchors.fill: parent
        source: "../Images/CompassModern/outerRing.svg"
        fillMode: Image.PreserveAspectFit
    }

    Image {
        anchors.fill: parent
        source: "../Images/CompassModern/reflection.svg"
        fillMode: Image.PreserveAspectFit
    }

    Image {
        anchors.fill: parent
        source: "../Images/CompassModern/centerGlass.svg"
        fillMode: Image.PreserveAspectFit
    }
}
