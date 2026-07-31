import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: messageInterface


    width: 400
    height: 250

    anchors.left: parent.left
    anchors.bottom: parent.bottom

    anchors.leftMargin: 20
    anchors.bottomMargin: 70
    
    radius: 10
    color: "#303030"

    border.width: 1
    border.color: "#666666"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        Label {
            text: "Message Interface"
            color: "white"
            font.pixelSize: 20
            Layout.alignment: Qt.AlignHCenter
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            color: "#202020"
            radius: 6

            ScrollView {
                anchors.fill: parent
                anchors.margins: 5

                TextArea {
                    id: messageDisplay

                    readOnly: true

                    text: "Waiting for messages..."

                    color: "white"

                    wrapMode: TextArea.Wrap

                    background: Rectangle {
                        color: "transparent"
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            TextField {
                id: messageInput

                Layout.fillWidth: true

                placeholderText: "Enter message..."

                onAccepted: sendButton.clicked()
            }

            Button {
                 id: sendButton

                 text: "Send"

                 onClicked: {
                 var message = messageInput.text.trim()

                 if (message.length > 0) {

                 if (_activeVehicle) {
                 _activeVehicle.sendTextMessage(message)

                 messageDisplay.text +=
                    "\n[You]: " + message
                } else {
                messageDisplay.text +=
                    "\n[Error]: No vehicle connected"
                 }

                  messageInput.clear()
                    }
                }
            }

            Button {
                text: "Clear"

                onClicked: {
                    messageDisplay.clear()
                }
            }
        }
    }
}
