import QtQuick

// Square icon button with hover-tint background, used for the left-toolbar
// icons in TopBar.qml (help/search/settings/system-monitor). Extracted from
// 4 near-identical Rectangle+Text+MouseArea blocks that differed only in
// icon, hover color, and whether they collapse to zero width when their
// Config.topbar*Icon toggle is off.
Rectangle {
    id: pill

    property var theme
    property var scaleFunc: function(v) { return v; }
    function s(v) { return scaleFunc(v); }

    property string icon: ""
    property real iconSize: 22
    property real size: 34
    property color hoverColor: theme ? theme.text : "#cdd6f4"
    property color idleColor: theme ? theme.text : "#cdd6f4"
    property color hoverBgColor: theme ? Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.6) : "#99454759"

    // Whether this pill is enabled in Config - controls the collapse-to-zero
    // width/opacity animation. Defaults true (always shown, no collapse).
    property bool active: true

    readonly property bool containsMouse: pillMa.containsMouse
    readonly property bool pressed: pillMa.pressed

    signal clicked()

    color: containsMouse ? hoverBgColor : "transparent"
    radius: s(10)
    width: active ? s(size) : 0
    height: s(size)
    visible: width > 0 || opacity > 0
    opacity: active ? 1.0 : 0.0
    clip: true

    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
    Behavior on opacity { NumberAnimation { duration: 300 } }
    Behavior on color { ColorAnimation { duration: 200 } }

    Text {
        anchors.centerIn: parent
        text: pill.icon
        font.family: "Iosevka Nerd Font"
        font.pixelSize: pill.s(pill.iconSize)
        color: pill.containsMouse ? pill.hoverColor : pill.idleColor
        Behavior on color { ColorAnimation { duration: 200 } }
        scale: pill.containsMouse ? 1.15 : 1.0
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
    }

    MouseArea {
        id: pillMa
        anchors.fill: parent
        hoverEnabled: true
        onClicked: pill.clicked()
    }
}
