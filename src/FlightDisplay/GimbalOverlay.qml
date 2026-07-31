import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QGroundControl
import QGroundControl.MultiVehicleManager

Rectangle {
    width: 220
    height: 220

    radius: 12
    color: "#66000000"

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 10

        Button {
            text: "▲"
            Layout.alignment: Qt.AlignHCenter

            onPressed: {
                console.log("Tilt Up")
            }
        }

        RowLayout {

            Button {
                text: "◀"

                onPressed: {
                    console.log("Pan Left")
                }
            }

            Rectangle {
                width: 60
                height: 60
                radius: 30
                color: "#404040"
            }

            Button {
                text: "▶"

                onPressed: {
                    console.log("Pan Right")
                }
            }
        }

        Button {
            text: "▼"

            Layout.alignment: Qt.AlignHCenter

            onPressed: {
                console.log("Tilt Down")
            }
        }
    }
}
