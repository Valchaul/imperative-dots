import QtQuick
import QtQuick.Window
import Quickshell
import "../"

Item {
    id: window
    focus: true

    Scaler {
        id: scaler
        currentWidth: Screen.width
    }
    function s(val) { return scaler.s(val); }

    MatugenColors { id: _theme }

    Rectangle {
        anchors.fill: parent
        radius: window.s(20)
        color: _theme.base
        border.color: _theme.surface0
        border.width: 1
        clip: true

        Loader {
            id: statsLoader
            anchors.fill: parent
            anchors.margins: window.s(20)
            source: "../quickactions/SystemUsage.qml"

            // Ambient properties SystemUsage.qml reads from its hosting Loader
            // (same contract Floating.qml's Loader fulfills for the sidebar widget).
            property var scaleFunc: window.s
            property var mochaColors: _theme
            property string activeEdge: "left"
        }
    }
}
