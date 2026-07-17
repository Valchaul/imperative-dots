import QtQuick
import QtQuick.Layouts
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
    readonly property color base: _theme.base
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color text: _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color crust: _theme.crust
    readonly property color mauve: _theme.mauve
    readonly property color sapphire: _theme.sapphire
    readonly property color red: _theme.red
    readonly property color peach: _theme.peach

    property string activeTab: "resources" // resources, processes, cores, storage

    readonly property color tabColor: {
        if (activeTab === "resources") return window.mauve;
        if (activeTab === "processes") return window.sapphire;
        if (activeTab === "cores") return window.red;
        return window.peach;
    }

    property real introMain: 0
    NumberAnimation on introMain { from: 0; to: 1.0; duration: 500; easing.type: Easing.OutExpo }

    Item {
        anchors.fill: parent
        scale: 0.97 + (0.03 * introMain)
        opacity: introMain
        transform: Translate { y: window.s(15) * (1 - introMain) }

        Rectangle {
            anchors.fill: parent
            radius: window.s(20)
            color: window.base
            border.color: window.surface0
            border.width: 1
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: window.s(20)
                spacing: window.s(16)

                Text {
                    text: "System Monitor"
                    font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: window.s(18)
                    color: window.text
                }

                // ==========================================
                // TABS
                // ==========================================
                HorizontalTabBar {
                    Layout.fillWidth: true
                    Layout.preferredHeight: window.s(48)
                    theme: window
                    scaleFunc: window.s
                    accentColor: window.tabColor
                    tabs: [
                        { tabId: "resources", icon: "", label: "Resources" },
                        { tabId: "processes", icon: "", label: "Processes" },
                        { tabId: "cores", icon: "", label: "Cores" },
                        { tabId: "storage", icon: "󰋊", label: "Storage" }
                    ]
                    activeTab: window.activeTab
                    onTabSelected: (tabId) => window.activeTab = tabId
                }

                // ==========================================
                // CONTENT
                // ==========================================
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Loader {
                        anchors.fill: parent
                        active: window.activeTab === "resources"
                        visible: active
                        source: "../quickactions/SystemUsageLight.qml"

                        property var scaleFunc: window.s
                        property var mochaColors: _theme
                        property string activeEdge: "left"
                    }

                    Loader {
                        anchors.fill: parent
                        active: window.activeTab === "processes"
                        visible: active
                        source: "ProcessList.qml"

                        property var scaleFunc: window.s
                        property var mochaColors: _theme
                    }

                    Loader {
                        anchors.fill: parent
                        active: window.activeTab === "cores"
                        visible: active
                        source: "CoreGrid.qml"

                        property var scaleFunc: window.s
                        property var mochaColors: _theme
                    }

                    Loader {
                        anchors.fill: parent
                        active: window.activeTab === "storage"
                        visible: active
                        source: "Storage.qml"

                        property var scaleFunc: window.s
                        property var mochaColors: _theme
                    }
                }
            }
        }
    }
}
