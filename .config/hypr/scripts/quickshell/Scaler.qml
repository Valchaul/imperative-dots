import QtQuick
import Quickshell
import Quickshell.Io
import "WindowRegistry.js" as LayoutMath

Item {
    id: root
    visible: false

    property real currentWidth: 1920.0
    property real currentHeight: 1080.0 // <-- ADDED

    // FIXED: Now passes both Width and Height to respect aspect ratio
    property real baseScale: LayoutMath.getScale(currentWidth, currentHeight, Config.uiScale)

    function s(val) {
        return LayoutMath.s(val, baseScale);
    }
}
