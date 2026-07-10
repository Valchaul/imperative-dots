import QtQuick

// Generic hover-reactive card: Rectangle whose color/border react to
// containsMouse, with an optional press-scale bounce. Put content directly
// inside { } - it becomes a child of the internal content Item, same
// default-property convention as TabScrollArea.
Rectangle {
    id: hoverCard

    property var theme
    property var scaleFunc: function(v) { return v; }
    function s(v) { return scaleFunc(v); }

    property color accentColor: theme ? theme.mauve : "#cba6f7"
    property color baseColor: theme ? theme.surface0 : "#313244"
    property color borderColorNormal: theme ? theme.surface1 : "#45475a"
    property real baseBgAlpha: 0.4
    property real hoverBgAlpha: 0.1
    property real hoverScale: 1.02
    property real pressScale: 0.97
    property bool clickable: true
    property bool hoverEnabled: true
    readonly property bool containsMouse: cardMa.containsMouse
    readonly property bool pressed: cardMa.pressed

    default property alias content: contentItem.data

    signal clicked()

    radius: s(12)
    color: cardMa.containsMouse ? Qt.alpha(accentColor, hoverBgAlpha) : Qt.alpha(baseColor, baseBgAlpha)
    border.color: cardMa.containsMouse ? accentColor : borderColorNormal
    border.width: 1
    scale: cardMa.pressed ? pressScale : (cardMa.containsMouse ? hoverScale : 1.0)

    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on border.color { ColorAnimation { duration: 200 } }
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

    // Declared before contentItem so any interactive content placed inside
    // (a nested button, another HoverCard, etc.) sits on top in z-order and
    // gets its own clicks first, rather than this card's own MouseArea
    // swallowing every click regardless of nesting.
    MouseArea {
        id: cardMa
        anchors.fill: parent
        hoverEnabled: hoverCard.hoverEnabled
        enabled: hoverCard.clickable
        cursorShape: hoverCard.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: hoverCard.clicked()
    }

    Item {
        id: contentItem
        anchors.fill: parent
    }
}
