import QtQuick
import QtQuick.Layouts

Rectangle {
    id: stepperBox

    property var theme
    property var scaleFunc: function(v) { return v; }
    function s(v) { return scaleFunc(v); }

    property string icon: ""
    property string label: ""
    property string description: ""
    property color accentColor: theme.mauve

    property real value: 0
    property real minValue: 0
    property real maxValue: 100
    property real stepSize: 1
    property int decimals: 0
    property string unit: ""
    property bool signedDisplay: false
    signal changed(real newValue)

    readonly property string displayText: {
        let v = value.toFixed(decimals);
        if (signedDisplay && value > 0) v = "+" + v;
        return v + unit;
    }

    Layout.fillWidth: true
    Layout.preferredHeight: contentRow.implicitHeight + s(28)
    radius: s(12)
    color: theme.surface0
    border.color: theme.surface1
    border.width: 1
    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

    RowLayout {
        id: contentRow
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: stepperBox.s(16)
        spacing: stepperBox.s(14)

        Item {
            Layout.preferredWidth: stepperBox.s(22)
            Layout.alignment: Qt.AlignVCenter
            Text {
                anchors.centerIn: parent
                text: stepperBox.icon
                font.family: "Iosevka Nerd Font"
                font.pixelSize: stepperBox.s(18)
                color: stepperBox.accentColor
                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: stepperBox.s(3)
            Text {
                text: stepperBox.label
                font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: stepperBox.s(14)
                color: stepperBox.theme.text
                Layout.fillWidth: true
            }
            Text {
                text: stepperBox.description
                font.family: "Inter"; font.pixelSize: stepperBox.s(11)
                color: Qt.alpha(stepperBox.theme.subtext0, 0.7)
                Layout.fillWidth: true
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            spacing: stepperBox.s(10)

            Rectangle {
                width: stepperBox.s(28); height: stepperBox.s(28); radius: stepperBox.s(6)
                color: minusMa.pressed
                    ? Qt.alpha(stepperBox.theme.base, 0.3)
                    : (minusMa.containsMouse ? Qt.alpha(stepperBox.theme.base, 0.2) : Qt.alpha(stepperBox.theme.base, 0.15))
                scale: minusMa.pressed ? 0.90 : (minusMa.containsMouse ? 1.08 : 1.0)
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                Behavior on color { ColorAnimation { duration: 200 } }
                Text {
                    anchors.centerIn: parent; text: "-"
                    font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: stepperBox.s(15)
                    color: stepperBox.accentColor
                }
                MouseArea {
                    id: minusMa
                    anchors.fill: parent; hoverEnabled: true
                    onClicked: stepperBox.changed(Math.max(stepperBox.minValue, parseFloat((stepperBox.value - stepperBox.stepSize).toFixed(stepperBox.decimals))))
                }
            }

            Text {
                text: stepperBox.displayText
                font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: stepperBox.s(14)
                color: stepperBox.accentColor
                Layout.minimumWidth: stepperBox.s(40); horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
                width: stepperBox.s(28); height: stepperBox.s(28); radius: stepperBox.s(6)
                color: plusMa.pressed
                    ? Qt.alpha(stepperBox.theme.base, 0.3)
                    : (plusMa.containsMouse ? Qt.alpha(stepperBox.theme.base, 0.2) : Qt.alpha(stepperBox.theme.base, 0.15))
                scale: plusMa.pressed ? 0.90 : (plusMa.containsMouse ? 1.08 : 1.0)
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                Behavior on color { ColorAnimation { duration: 200 } }
                Text {
                    anchors.centerIn: parent; text: "+"
                    font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: stepperBox.s(15)
                    color: stepperBox.accentColor
                }
                MouseArea {
                    id: plusMa
                    anchors.fill: parent; hoverEnabled: true
                    onClicked: stepperBox.changed(Math.min(stepperBox.maxValue, parseFloat((stepperBox.value + stepperBox.stepSize).toFixed(stepperBox.decimals))))
                }
            }
        }
    }
}
