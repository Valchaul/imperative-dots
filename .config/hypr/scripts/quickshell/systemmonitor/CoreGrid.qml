import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: root

    function s(val) { return typeof scaleFunc === "function" ? scaleFunc(val) : val; }
    property color cText: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.text : "#cdd6f4"
    property color cSubtext0: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.subtext0 : "#a6adc8"
    property color cSurface0: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.surface0 : "#313244"
    property color cRed: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.red : "#f38ba8"

    property bool active: parent !== null && parent.visible !== undefined ? parent.visible : true

    property var coreUsage: []

    function lerp(a, b, t) { return a + (b - a) * t; }
    function heatColor(pct) {
        let t = Math.max(0, Math.min(1, pct / 100));
        return Qt.rgba(
            root.lerp(root.cSurface0.r, root.cRed.r, t),
            root.lerp(root.cSurface0.g, root.cRed.g, t),
            root.lerp(root.cSurface0.b, root.cRed.b, t),
            1.0
        );
    }

    Timer {
        id: refreshTimer
        interval: 2000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: { fetchProc.running = false; fetchProc.running = true; }
    }

    Process {
        id: fetchProc
        command: ["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/systemmonitor/percore_fetch.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let text = this.text ? this.text.trim() : "";
                if (!text) return;
                root.coreUsage = text.split(",").map(v => parseFloat(v) || 0);
            }
        }
    }

    GridLayout {
        anchors.fill: parent
        columns: Math.max(1, Math.ceil(Math.sqrt(Math.max(1, root.coreUsage.length))))
        rowSpacing: root.s(8)
        columnSpacing: root.s(8)

        Repeater {
            model: root.coreUsage

            delegate: Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: root.s(8)
                color: root.heatColor(modelData)
                Behavior on color { ColorAnimation { duration: 400 } }

                Text {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: root.s(6)
                    text: "C" + index
                    font.family: "JetBrains Mono"; font.pixelSize: root.s(10); font.bold: true
                    color: modelData >= 50 ? Qt.rgba(1, 1, 1, 0.85) : root.cSubtext0
                }
                Text {
                    anchors.centerIn: parent
                    text: Math.round(modelData) + "%"
                    font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: root.s(15)
                    color: modelData >= 50 ? "white" : root.cText
                }
            }
        }
    }
}
