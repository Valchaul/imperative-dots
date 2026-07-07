import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: root

    function s(val) { return typeof scaleFunc === "function" ? scaleFunc(val) : val; }
    property color cText: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.text : "#cdd6f4"
    property color cSubtext0: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.subtext0 : "#a6adc8"
    property color cSurface0: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.surface0 : "#313244"
    property color cSurface1: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.surface1 : "#45475a"
    property color cMauve: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.mauve : "#cba6f7"
    property color cRed: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.red : "#f38ba8"

    property bool active: parent !== null && parent.visible !== undefined ? parent.visible : true

    ListModel { id: processModel }

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
        command: ["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/systemmonitor/process_fetch.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let text = this.text ? this.text.trim() : "";
                if (!text) return;

                let lines = text.split("\n");
                let newData = [];
                for (let i = 0; i < lines.length; i++) {
                    let parts = lines[i].split("");
                    if (parts.length < 5) continue;
                    newData.push({
                        pid: parts[0],
                        cpu: parseFloat(parts[1]) || 0,
                        core: parseFloat(parts[2]) || 0,
                        mem: parseFloat(parts[3]) || 0,
                        name: parts[4]
                    });
                }

                // In-place update keeps ListView delegates alive instead of destroying
                // and recreating all ~80 rows every 2s.
                while (processModel.count < newData.length) processModel.append({ pid: "", cpu: 0, core: 0, mem: 0, name: "" });
                while (processModel.count > newData.length) processModel.remove(processModel.count - 1);
                for (let j = 0; j < newData.length; j++) {
                    let cur = processModel.get(j);
                    if (cur.pid !== newData[j].pid) processModel.setProperty(j, "pid", newData[j].pid);
                    if (cur.cpu !== newData[j].cpu) processModel.setProperty(j, "cpu", newData[j].cpu);
                    if (cur.core !== newData[j].core) processModel.setProperty(j, "core", newData[j].core);
                    if (cur.mem !== newData[j].mem) processModel.setProperty(j, "mem", newData[j].mem);
                    if (cur.name !== newData[j].name) processModel.setProperty(j, "name", newData[j].name);
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: root.s(6)

        // Header row
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.s(24)
            Layout.leftMargin: root.s(12)
            Layout.rightMargin: root.s(12)

            Text { text: "PID"; Layout.preferredWidth: root.s(70); font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: root.s(11); color: root.cSubtext0 }
            Text { text: "NAME"; Layout.fillWidth: true; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: root.s(11); color: root.cSubtext0 }
            Text { text: "CPU%"; Layout.preferredWidth: root.s(65); horizontalAlignment: Text.AlignRight; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: root.s(11); color: root.cSubtext0 }
            Text { text: "CORE%"; Layout.preferredWidth: root.s(65); horizontalAlignment: Text.AlignRight; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: root.s(11); color: root.cSubtext0 }
            Text { text: "MEM%"; Layout.preferredWidth: root.s(65); horizontalAlignment: Text.AlignRight; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: root.s(11); color: root.cSubtext0 }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: root.cSurface1 }

        ListView {
            id: procView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: processModel
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {}

            delegate: Rectangle {
                width: procView.width
                height: root.s(30)
                radius: root.s(6)
                color: rowMa.containsMouse ? root.cSurface0 : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: root.s(12)
                    anchors.rightMargin: root.s(12)

                    Text {
                        text: model.pid
                        Layout.preferredWidth: root.s(70)
                        font.family: "JetBrains Mono"; font.pixelSize: root.s(12); color: root.cSubtext0
                    }
                    Text {
                        text: model.name
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        font.family: "JetBrains Mono"; font.pixelSize: root.s(12); color: root.cText
                    }
                    Text {
                        text: model.cpu.toFixed(1)
                        Layout.preferredWidth: root.s(65)
                        horizontalAlignment: Text.AlignRight
                        font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(12)
                        color: model.cpu >= 50 ? root.cRed : root.cText
                    }
                    Text {
                        text: model.core.toFixed(1)
                        Layout.preferredWidth: root.s(65)
                        horizontalAlignment: Text.AlignRight
                        font.family: "JetBrains Mono"; font.pixelSize: root.s(12)
                        color: model.core >= 100 ? root.cRed : root.cSubtext0
                    }
                    Text {
                        text: model.mem.toFixed(1)
                        Layout.preferredWidth: root.s(65)
                        horizontalAlignment: Text.AlignRight
                        font.family: "JetBrains Mono"; font.pixelSize: root.s(12); color: root.cSubtext0
                    }
                }

                MouseArea { id: rowMa; anchors.fill: parent; hoverEnabled: true }
            }
        }
    }
}
