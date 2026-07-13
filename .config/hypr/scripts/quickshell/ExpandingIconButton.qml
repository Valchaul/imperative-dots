import QtQuick
import QtQuick.Layouts

// Icon-only pill that expands leftward on hover to reveal a label next to a
// fixed-position icon (right-anchored Row). Extracted from the DND toggle
// (NotificationCenterPopup.qml) and the logout button (BatteryPopup.qml),
// which had grown into byte-for-byte duplicates of each other (and of
// themselves again in BatteryPopupAlt.qml).
//
// color/border.color are left as plain overridable Rectangle properties
// rather than baked into the component, since consumers differ on whether
// there's a persistent "enabled" state on top of hover (DND) or just hover
// (logout) - same reasoning as HoverCard's isToday override in
// CalendarPopup.qml. Bind them against the exposed `containsMouse`.
Rectangle {
    id: btn

    property var theme
    property var scaleFunc: function(v) { return v; }
    function s(v) { return scaleFunc(v); }

    property real collapsedSize: 40
    property real radiusSize: 12
    property real iconSize: 18
    property real labelSize: 13
    property real rightPadding: 10
    property real itemSpacing: 8

    property string icon: ""
    property string label: ""
    property color iconColor: theme ? theme.text : "#cdd6f4"
    property color labelColor: theme ? theme.text : "#cdd6f4"

    readonly property bool containsMouse: btnMa.containsMouse
    readonly property bool pressed: btnMa.pressed

    signal clicked()

    width: containsMouse ? s(collapsedSize) + labelText.implicitWidth + s(itemSpacing) : s(collapsedSize)
    height: s(collapsedSize)
    Layout.preferredWidth: width
    Layout.preferredHeight: height
    radius: s(radiusSize)
    border.width: 1
    clip: true

    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: btn.s(btn.rightPadding)
        anchors.verticalCenter: parent.verticalCenter
        spacing: btn.s(btn.itemSpacing)

        Text {
            id: labelText
            text: btn.label
            font.family: "JetBrains Mono"
            font.weight: Font.Bold
            font.pixelSize: btn.s(btn.labelSize)
            color: btn.labelColor
            anchors.verticalCenter: parent.verticalCenter
            opacity: btn.containsMouse ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 250 } }
        }

        Text {
            font.family: "Iosevka Nerd Font"
            font.pixelSize: btn.s(btn.iconSize)
            color: btn.iconColor
            text: btn.icon
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    MouseArea {
        id: btnMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
