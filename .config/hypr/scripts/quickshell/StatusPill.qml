import QtQuick
import QtQuick.Layouts

// Rounded topbar module pod (kb-layout/wifi/bluetooth/cpu/temp/notifications/
// volume/battery), extracted from TopBar.qml's `sysLayout` Row, where all 8
// pills repeated the same hover-tint background, active-state gradient
// overlay, collapse-to-zero-width animation, hover scale, and staggered
// entrance (Timer + Translate) - differing only in their icon/label content
// and in which live state should be considered "active".
Rectangle {
    id: pill

    property var theme
    property var scaleFunc: function(v) { return v; }
    function s(v) { return scaleFunc(v); }

    property color normalBgColor: theme ? Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.4) : "#66313244"
    property color hoverBgColor: theme ? Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.6) : "#99454759"
    property color activeColorStart: theme ? theme.mauve : "#cba6f7"
    property color activeColorEnd: Qt.lighter(activeColorStart, 1.3)

    // Live "is this pill's state notable" flag - fades the gradient overlay
    // in/out. Distinct from `collapsed`, which fully removes the pill.
    property bool active: false
    property bool collapsed: false
    property real contentPadding: 24
    property string contentAlignment: "left" // "left" | "center"
    // Override the content-driven width with an exact value (e.g. an
    // icon-only collapsed state that should match other fixed-size pills).
    property real forcedWidth: -1

    // Staggered entrance: bind `introTrigger` to the bar's own "am I ready to
    // animate in" flag, `staggerDelay` to this pill's position in the sequence.
    property bool introTrigger: false
    property int staggerDelay: 0

    readonly property bool containsMouse: pillMa.containsMouse
    readonly property bool pressed: pillMa.pressed
    default property alias content: innerRow.data

    signal clicked()

    radius: s(10)
    clip: true
    color: containsMouse ? hoverBgColor : normalBgColor
    Behavior on color { ColorAnimation { duration: 200 } }

    width: collapsed ? 0 : (forcedWidth >= 0 ? forcedWidth : innerRow.implicitWidth + s(contentPadding))
    visible: width > 0
    Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }

    scale: containsMouse ? 1.05 : 1.0
    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

    property bool initAnimTrigger: false
    Timer { running: pill.introTrigger && !pill.initAnimTrigger; interval: pill.staggerDelay; onTriggered: pill.initAnimTrigger = true }
    opacity: initAnimTrigger ? 1 : 0
    transform: Translate { y: pill.initAnimTrigger ? 0 : pill.s(15); Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } } }
    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        radius: pill.radius
        opacity: pill.active ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: pill.activeColorStart; Behavior on color { ColorAnimation { duration: 300 } } }
            GradientStop { position: 1.0; color: pill.activeColorEnd; Behavior on color { ColorAnimation { duration: 300 } } }
        }
    }

    Row {
        id: innerRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: pill.contentAlignment === "left" ? parent.left : undefined
        anchors.leftMargin: pill.contentAlignment === "left" ? pill.s(12) : 0
        anchors.horizontalCenter: pill.contentAlignment === "center" ? parent.horizontalCenter : undefined
        spacing: pill.s(8)
    }

    MouseArea {
        id: pillMa
        anchors.fill: parent
        hoverEnabled: true
        onClicked: pill.clicked()
    }
}
