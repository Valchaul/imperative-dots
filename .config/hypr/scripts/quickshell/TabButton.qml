import QtQuick

Item {
    id: tabButton

    property var theme
    property var scaleFunc: function(v) { return v; }
    function s(v) { return scaleFunc(v); }

    property string icon: ""
    property string label: ""
    property bool active: false

    // Colors default to a Catppuccin-style "crust on colored pill" active state,
    // matching how the tab highlight background is usually themed.
    property color activeColor: theme.crust
    property color inactiveColor: theme.subtext0
    property color hoverColor: theme.text

    property int activeFontWeight: Font.Black
    property int inactiveFontWeight: Font.Medium

    // "center" (equal-width segments sharing an external sliding pill, e.g. a
    // horizontal tab bar) or "left" (full-width sidebar row, icon column +
    // label filling the rest, e.g. a vertical tab list).
    property string contentAlignment: "center"
    property real leftPadding: 15
    property real iconColumnWidth: 24
    // Extra push applied to the content while active - the "slide right on
    // select" touch used by vertical sidebars. Leave 0 for no effect.
    property real activeShift: 0

    property real iconSize: 16
    property real labelSize: 13
    property real spacing: 8
    property bool showLabel: true

    // Background tint for inactive rows on hover - a per-row highlight, as
    // opposed to the shared sliding pill some tab bars draw externally
    // (leave transparent, the default, when a consumer already has that).
    property color hoverBgColor: "transparent"
    property real backgroundRadius: 8

    signal clicked()

    readonly property color currentColor: active ? activeColor : (tabMa.containsMouse ? hoverColor : inactiveColor)

    implicitWidth: s(iconColumnWidth) + s(spacing) + metricsText.implicitWidth + s(leftPadding) * 2
    implicitHeight: s(iconColumnWidth)

    Text {
        id: metricsText
        visible: false
        text: tabButton.label
        font.family: "JetBrains Mono"
        font.pixelSize: tabButton.s(tabButton.labelSize)
    }

    Rectangle {
        anchors.fill: parent
        radius: tabButton.s(tabButton.backgroundRadius)
        color: (!tabButton.active && tabMa.containsMouse) ? tabButton.hoverBgColor : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // "left" mode: icon in a fixed-width column on the left, label filling
    // the rest of the row.
    Item {
        visible: tabButton.contentAlignment === "left"
        anchors.fill: parent

        transform: Translate {
            x: tabButton.active ? tabButton.s(tabButton.activeShift) : 0
            Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
        }

        Item {
            id: leftIconItem
            width: tabButton.s(tabButton.iconColumnWidth)
            height: parent.height
            anchors.left: parent.left
            anchors.leftMargin: tabButton.s(tabButton.leftPadding)

            Text {
                anchors.centerIn: parent
                text: tabButton.icon
                font.family: "Iosevka Nerd Font"
                font.pixelSize: tabButton.s(tabButton.iconSize)
                color: tabButton.currentColor
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }

        Text {
            visible: tabButton.showLabel && tabButton.label !== ""
            text: tabButton.label
            font.family: "JetBrains Mono"
            font.weight: tabButton.active ? tabButton.activeFontWeight : tabButton.inactiveFontWeight
            font.pixelSize: tabButton.s(tabButton.labelSize)
            color: tabButton.currentColor
            Behavior on color { ColorAnimation { duration: 200 } }

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: leftIconItem.right
            anchors.leftMargin: tabButton.s(tabButton.spacing)
            anchors.right: parent.right
            anchors.rightMargin: tabButton.s(tabButton.leftPadding)
        }
    }

    // "center" mode: icon+label form a single Row, auto-sized to its content
    // and centered as one unit, so both margins around the pair stay equal -
    // anchoring the icon and label to each other independently (rather than
    // as a group) left one side with extra space, per user report.
    Row {
        visible: tabButton.contentAlignment === "center"
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: tabButton.s(tabButton.spacing)

        transform: Translate {
            x: tabButton.active ? tabButton.s(tabButton.activeShift) : 0
            Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
        }

        Item {
            width: tabButton.s(tabButton.iconColumnWidth)
            height: centerLabel.implicitHeight

            Text {
                anchors.centerIn: parent
                text: tabButton.icon
                font.family: "Iosevka Nerd Font"
                font.pixelSize: tabButton.s(tabButton.iconSize)
                color: tabButton.currentColor
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }

        Text {
            id: centerLabel
            visible: tabButton.showLabel && tabButton.label !== ""
            text: tabButton.label
            font.family: "JetBrains Mono"
            font.weight: tabButton.active ? tabButton.activeFontWeight : tabButton.inactiveFontWeight
            font.pixelSize: tabButton.s(tabButton.labelSize)
            color: tabButton.currentColor
            Behavior on color { ColorAnimation { duration: 200 } }
        }
    }

    MouseArea {
        id: tabMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tabButton.clicked()
    }
}
