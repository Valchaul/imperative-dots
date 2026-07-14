import QtQuick

// Static topbar chrome: the translucent rounded container shared by
// leftContent, workspacesBox, mediaBox, the tray box, and the sys-pill box
// in TopBar.qml - all repeated the same base-color fill + subtle text-alpha
// border + rounded radius, differing only in the border's alpha and their
// own positioning/width-collapse logic (left untouched here; set those at
// the instantiation site same as any Rectangle).
Rectangle {
    id: section

    property var theme
    property var scaleFunc: function(v) { return v; }
    function s(v) { return scaleFunc(v); }

    property color bgColor: theme ? theme.base : "#1e1e2e"
    property real bgAlpha: 0.75
    property color borderBaseColor: theme ? theme.text : "#cdd6f4"
    property real borderAlpha: 0.08

    default property alias content: contentItem.data

    color: Qt.rgba(bgColor.r, bgColor.g, bgColor.b, bgAlpha)
    radius: s(14)
    border.width: 1
    border.color: Qt.rgba(borderBaseColor.r, borderBaseColor.g, borderBaseColor.b, borderAlpha)

    Item {
        id: contentItem
        anchors.fill: parent
    }
}
