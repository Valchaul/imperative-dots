import QtQuick
import QtQuick.Layouts

// Draggable percent-fill slider (rounded track + gradient fill), extracted from
// the brightness/volume sliders in BatteryPopup.qml and the master/per-app
// volume sliders in VolumePopup.qml, which had grown into near-identical
// Rectangle+Gradient+MouseArea blocks differing only in colors and sizing.
//
// Command dispatch (brightnessctl/wpctl/audio_control.sh) and any extra
// visual-rate throttling are intentionally left to the consumer via the
// dragMoved/pressed signals rather than baked in here, since each caller
// throttles differently (some need a second, frame-rate-capped tier on top
// of the command throttle to avoid expensive ListView model writes).
Item {
    id: slider

    property var theme
    property var scaleFunc: function(v) { return v; }
    function s(v) { return scaleFunc(v); }

    property real value: 0 // 0-100, current fill percent

    property color trackColor: theme ? theme.surface1 : "#45475a"
    property color trackBorderColor: theme ? theme.surface2 : "#585b70"
    property color fillColorStart: theme ? theme.mauve : "#cba6f7"
    property color fillColorEnd: Qt.lighter(fillColorStart, 1.15)

    property real hoverOpacity: 1.0
    property real normalOpacity: 0.85
    property real dimOpacity: 0.3
    property bool dimmed: false

    // Bind to the consumer's own "is the user actively dragging this" flag so
    // the width Behavior doesn't fight live updates while pressed.
    property bool suppressAnimation: false
    property int animDuration: 250

    readonly property bool containsMouse: sliderMa.containsMouse
    readonly property bool pressed: sliderMa.pressed

    signal dragStarted()
    signal dragMoved(int pct)
    signal dragEnded()

    implicitHeight: s(18)

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: slider.trackColor
        border.color: slider.trackBorderColor
        border.width: 1
        clip: true

        Rectangle {
            height: parent.height
            width: parent.width * (Math.min(100, Math.max(0, slider.value)) / 100)
            radius: height / 2
            opacity: slider.dimmed ? slider.dimOpacity : (slider.containsMouse ? slider.hoverOpacity : slider.normalOpacity)
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Behavior on width { enabled: !slider.suppressAnimation; NumberAnimation { duration: slider.animDuration; easing.type: Easing.OutQuint } }

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: slider.fillColorStart; Behavior on color { ColorAnimation { duration: 300 } } }
                GradientStop { position: 1.0; color: slider.fillColorEnd; Behavior on color { ColorAnimation { duration: 300 } } }
            }
        }
    }

    MouseArea {
        id: sliderMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: (mouse) => { slider.dragStarted(); updatePct(mouse.x); }
        onPositionChanged: (mouse) => { if (pressed) updatePct(mouse.x); }
        onReleased: slider.dragEnded()

        function updatePct(mx) {
            let pct = Math.max(0, Math.min(100, Math.round((mx / width) * 100)));
            slider.dragMoved(pct);
        }
    }
}
