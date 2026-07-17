import QtQuick
import QtQuick.Layouts

// Small icon(+label) action button - idle is an outlined/tinted pill in
// `accentColor`, hover flips the background to a solid fill of that color
// and swaps the text/icon to a contrasting color. Extracted from the
// near-identical "Save"/"Apply" buttons in SettingsPopup.qml, which had
// grown into 3 independent Rectangle+Text+MouseArea copies differing only
// in color, icon, and whether they had a busy/loading state.
Rectangle {
    id: btn

    property var theme
    property var scaleFunc: function(v) { return v; }
    function s(v) { return scaleFunc(v); }

    property string icon: ""
    property string label: ""
    property color accentColor: theme ? theme.mauve : "#cba6f7"
    property color idleBgColor: theme ? theme.surface1 : "#45475a"
    property color hoverTextColor: theme ? theme.base : "#1e1e2e"

    // While busy: label swaps to `busyText`, clicks are blocked, and the
    // hover fill/press dip are suppressed (nothing to react to a mouse that
    // can no longer trigger anything).
    property bool busy: false
    property string busyText: "…"

    property string fontFamily: "JetBrains Mono"
    property int fontWeight: Font.Medium
    property real iconSize: 14
    property real labelSize: 10
    property real itemSpacing: 6
    property real pressScale: 0.95

    readonly property bool containsMouse: btnMa.containsMouse
    readonly property bool pressed: btnMa.pressed
    readonly property bool hoverActive: containsMouse && !busy

    signal clicked()

    implicitWidth: contentRow.implicitWidth + s(24)
    implicitHeight: s(30)
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    radius: s(7)
    color: hoverActive ? accentColor : idleBgColor
    border.color: hoverActive ? accentColor : Qt.alpha(accentColor, 0.4)
    border.width: 1
    Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutExpo } }
    Behavior on border.color { ColorAnimation { duration: 180 } }

    scale: btnMa.pressed && !busy ? pressScale : 1.0
    // Snap down instantly on press (so even a fast click registers the dip),
    // then ease back out on release.
    Behavior on scale {
        enabled: !btnMa.pressed
        NumberAnimation { duration: 200; easing.type: Easing.OutBack }
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: btn.s(btn.itemSpacing)

        Text {
            visible: btn.icon !== ""
            text: btn.icon
            font.family: "Iosevka Nerd Font"
            font.pixelSize: btn.s(btn.iconSize)
            color: btn.hoverActive ? btn.hoverTextColor : btn.accentColor
            Behavior on color { ColorAnimation { duration: 180 } }
        }

        Text {
            text: btn.busy ? btn.busyText : btn.label
            font.family: btn.fontFamily
            font.weight: btn.fontWeight
            font.pixelSize: btn.s(btn.labelSize)
            color: btn.hoverActive ? btn.hoverTextColor : btn.accentColor
            Behavior on color { ColorAnimation { duration: 180 } }
        }
    }

    MouseArea {
        id: btnMa
        anchors.fill: parent
        hoverEnabled: true
        enabled: !btn.busy
        cursorShape: btn.busy ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
