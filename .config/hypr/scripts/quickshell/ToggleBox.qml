import QtQuick
import QtQuick.Layouts

Rectangle {
    id: toggleBox

    property var theme
    property var scaleFunc: function(v) { return v; }
    function s(v) { return scaleFunc(v); }

    property string icon: ""
    property string label: ""
    property string description: ""
    property color accentColor: theme.mauve
    property bool checked: false
    signal toggled()

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
        anchors.margins: toggleBox.s(16)
        spacing: toggleBox.s(14)

        Item {
            Layout.preferredWidth: toggleBox.s(22)
            Layout.alignment: Qt.AlignVCenter
            Text {
                anchors.centerIn: parent
                text: toggleBox.icon
                font.family: "Iosevka Nerd Font"
                font.pixelSize: toggleBox.s(18)
                color: toggleBox.accentColor
                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: toggleBox.s(3)
            Text {
                text: toggleBox.label
                font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: toggleBox.s(14)
                color: toggleBox.theme.text
                Layout.fillWidth: true
            }
            Text {
                text: toggleBox.description
                font.family: "Inter"; font.pixelSize: toggleBox.s(11)
                color: Qt.alpha(toggleBox.theme.subtext0, 0.7)
                Layout.fillWidth: true
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            Layout.preferredWidth: toggleBox.s(40)
            Layout.preferredHeight: toggleBox.s(22)
            radius: toggleBox.s(11)
            scale: switchMa.containsMouse ? 1.05 : 1.0
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
            color: toggleBox.checked ? toggleBox.accentColor : toggleBox.theme.surface2
            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

            Rectangle {
                width: toggleBox.s(16); height: toggleBox.s(16); radius: toggleBox.s(8)
                color: toggleBox.checked ? toggleBox.theme.base : toggleBox.theme.surface0
                y: toggleBox.s(3); x: toggleBox.checked ? toggleBox.s(21) : toggleBox.s(3)
                Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
            }

            MouseArea {
                id: switchMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: toggleBox.toggled()
            }
        }
    }
}
