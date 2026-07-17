import QtQuick
import QtQuick.Layouts

Item {
    id: tabBar

    property var theme
    property var scaleFunc: function(v) { return v; }
    function s(v) { return scaleFunc(v); }

    // [{ tabId, icon, label }, ...]
    property var tabs: []
    property string activeTab: ""

    // Single accent driving the sliding highlight's gradient - bind a
    // per-tab color from the consumer (e.g. a computed property) if the
    // highlight should change color per tab, or a constant otherwise.
    property color accentColor: theme ? theme.mauve : "gray"

    property color containerColor: "#0dffffff"
    property color containerBorderColor: "#1affffff"
    property real containerRadius: s(12)

    property color activeColor: theme ? theme.crust : "black"
    property color inactiveColor: theme ? theme.subtext0 : "gray"
    property color hoverColor: theme ? theme.text : "white"
    property int activeFontWeight: Font.Black
    property int inactiveFontWeight: Font.Black

    signal tabSelected(string tabId)

    implicitHeight: s(48)

    Rectangle {
        anchors.fill: parent
        radius: tabBar.containerRadius
        color: tabBar.containerColor
        border.color: tabBar.containerBorderColor
        border.width: 1

        Rectangle {
            width: (parent.width - tabBar.s(2)) / Math.max(1, tabBar.tabs.length)
            height: parent.height - tabBar.s(2)
            y: tabBar.s(1)
            radius: tabBar.s(9)
            x: (width * tabBar.tabs.findIndex(t => t.tabId === tabBar.activeTab)) + tabBar.s(1)
            Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: tabBar.accentColor; Behavior on color { ColorAnimation { duration: 300 } } }
                GradientStop { position: 1.0; color: Qt.lighter(tabBar.accentColor, 1.15); Behavior on color { ColorAnimation { duration: 300 } } }
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Repeater {
                model: tabBar.tabs

                delegate: TabButton {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 0
                    theme: tabBar.theme
                    scaleFunc: tabBar.scaleFunc
                    contentAlignment: "center"
                    icon: modelData.icon
                    label: modelData.label
                    active: tabBar.activeTab === modelData.tabId
                    activeColor: tabBar.activeColor
                    inactiveColor: tabBar.inactiveColor
                    hoverColor: tabBar.hoverColor
                    activeFontWeight: tabBar.activeFontWeight
                    inactiveFontWeight: tabBar.inactiveFontWeight
                    onClicked: tabBar.tabSelected(modelData.tabId)
                }
            }
        }
    }
}
