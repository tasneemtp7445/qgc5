import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {

    width: 170
    height: 170

    color: "transparent"

    Column {

        anchors.centerIn: parent
        spacing: 6

        Button {
            text: "▲"
            width: 60
            onPressed: console.log("Tilt Up")
        }

        Row {

            spacing: 6

            Button {
                text: "◀"
                width: 60
                onPressed: console.log("Pan Left")
            }

            Button {
                text: "▶"
                width: 60
                onPressed: console.log("Pan Right")
            }
        }

        Button {
            text: "▼"
            width: 60
            onPressed: console.log("Tilt Down")
        }
    }
}
