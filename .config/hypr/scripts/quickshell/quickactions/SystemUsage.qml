//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../" // Resolves the SysData singleton from the parent directory

Item {
    id: root

    Caching { id: paths }

    // By NOT declaring these as local properties, we allow QML to naturally 
    // inherit them from the parent Loader in Floating.qml
    property string safeActiveEdge: typeof activeEdge !== "undefined" ? activeEdge : "left"

    function s(val) {
        return typeof scaleFunc === "function" ? scaleFunc(val) : val;
    }

    property var requestedLayoutTemplate: [
        { x: 0.0, y: 0.0, w: 0.333, h: 0.5 },
        { x: 0.333, y: 0.0, w: 0.334, h: 0.5 },
        { x: 0.667, y: 0.0, w: 0.333, h: 0.5 },
        { x: 0.0, y: 0.5, w: 0.5, h: 0.5 },
        { x: 0.5, y: 0.5, w: 0.5, h: 0.5 }
    ]

    property real baseW: s(360)
    property real baseL: s(250)

    property real preferredWidth: root.safeActiveEdge === "bottom" ? baseL + 80 : baseW
    property real preferredExtraLength: root.safeActiveEdge === "bottom" ? baseW : baseL

    property real counterRotation: {
        if (root.safeActiveEdge === "right") return 180;
        if (root.safeActiveEdge === "bottom") return 90;
        return 0; 
    }

    // Mathematical coordinate mapping to perfectly sync with Floating.qml skeletons
    property real sp: s(10)
    function cellX(mx) { return (mx * orientedRoot.width) + (mx > 0 ? sp / 2 : 0); }
    function cellY(my) { return (my * orientedRoot.height) + (my > 0 ? sp / 2 : 0); }
    function cellW(mx, mw) { return (mw * orientedRoot.width) - ((mx > 0 ? sp / 2 : 0) + ((mx + mw) < 0.99 ? sp / 2 : 0)); }
    function cellH(my, mh) { return (mh * orientedRoot.height) - ((my > 0 ? sp / 2 : 0) + ((my + mh) < 0.99 ? sp / 2 : 0)); }

    // Unified Matugen Theming (Strict Type Binding)
    property color cBase: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.base : "#1e1e2e"
    property color cCrust: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.crust : "#11111b"
    property color cSurface0: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.surface0 : "#313244"
    property color cSurface1: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.surface1 : "#45475a"
    property color cText: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.text : "#cdd6f4"
    property color cSubtext0: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.subtext0 : "#a6adc8"
    property color cMauve: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.mauve : "#cba6f7"
    property color cSapphire: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.sapphire : "#74c7ec"
    property color cGreen: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.green : "#a6e3a1"
    property color cPeach: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.peach : "#fab387"
    property color cYellow: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.yellow : "#f9e2af"
    property color cRed: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.red : "#f38ba8"

    property color accent: cMauve
    property color textPrimary: cText
    property color textSecondary: cSubtext0
    property color bgSurface: cSurface0
    property string iconFont: "Iosevka Nerd Font"

    function alpha(color, a) { return Qt.rgba(color.r, color.g, color.b, a); }

    property bool widgetVisible: parent !== null && parent.visible !== undefined ? parent.visible : true
    
    property real globalWavePhase: 0.0
    NumberAnimation on globalWavePhase {
        from: 0; to: Math.PI * 2; duration: 1800; loops: Animation.Infinite; running: root.widgetVisible
    }

    Component.onCompleted: SysData.subscribe()
    Component.onDestruction: SysData.unsubscribe()

    // --- ANIMATED DATA STATE BINDINGS ---
    // Smooths out raw SysData to drive both the visual wave and the dynamic text counters in constant 800ms time
    property real rawCpu: isNaN(SysData.cpu) ? 0.0 : SysData.cpu / 100.0
    property real cpuUsage: rawCpu
    Behavior on cpuUsage { NumberAnimation { duration: 800; easing.type: Easing.OutQuint } }

    property real rawTemp: isNaN(SysData.temp) ? 0.0 : SysData.temp
    property real tempC: rawTemp
    Behavior on tempC { NumberAnimation { duration: 800; easing.type: Easing.OutQuint } }

    property real rawRam: isNaN(SysData.ramPercent) ? 0.0 : SysData.ramPercent / 100.0
    property real ramUsage: rawRam
    Behavior on ramUsage { NumberAnimation { duration: 800; easing.type: Easing.OutQuint } }

    property real rawRamGb: isNaN(SysData.ramGb) ? 0.0 : SysData.ramGb
    property real ramUsedGb: rawRamGb
    Behavior on ramUsedGb { NumberAnimation { duration: 800; easing.type: Easing.OutQuint } }

    // Network values snap instantly (no Behavior) because large byte jumps look erratic when interpolated
    property real netRx: isNaN(SysData.netRx) ? 0 : SysData.netRx
    property real netTx: isNaN(SysData.netTx) ? 0 : SysData.netTx

    property string rxSpeedStr: root.formatBytes(netRx)
    property string txSpeedStr: root.formatBytes(netTx)

    property real diskUsagePercent: 0.0
    Behavior on diskUsagePercent { NumberAnimation { duration: 800; easing.type: Easing.OutQuint } }
    
    property string diskUsageText: "..."
    property var diskFolders: []

    function formatBytes(bytes) {
        if (bytes <= 0 || isNaN(bytes)) return "0 B/s";
        let k = 1024, sizes = ["B/s", "KB/s", "MB/s", "GB/s"];
        let i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + " " + sizes[i];
    }

    Timer {
        id: diskTimer
        interval: 60000
        running: true; repeat: true; triggeredOnStart: true
        onTriggered: { diskProc.running = false; diskProc.running = true; }
    }

    Process {
        id: diskProc
        command: ["bash", "-c", "df -h ~ | awk 'NR==2{printf(\"%s;%s / %s;\", $5, $3, $2)}'; du -sh ~/.config ~/.cache ~/.local/share ~/Downloads ~/Documents ~/Pictures ~/Videos ~/Music ~/Projects ~/Games 2>/dev/null | sort -hr | head -n 5 | awk '{printf(\"%s|%s,\", $1, $2)}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let text = this.text ? this.text.trim() : "";
                if (!text) return;
                
                var parts = text.split(";");
                if (parts.length >= 3) {
                    root.diskUsagePercent = parseFloat(parts[0].replace('%', '')) / 100.0;
                    root.diskUsageText = parts[1];
                    
                    var folderList = parts[2].split(",").filter(str => str.length > 0);
                    var newFolders = [];
                    var maxVal = 0;
                    
                    for (var i = 0; i < folderList.length; i++) {
                        var fp = folderList[i].split("|");
                        if (fp.length === 2) {
                            var sizeStr = fp[0];
                            var pathStr = fp[1].split("/").pop(); 
                            
                            var num = parseFloat(sizeStr);
                            if (sizeStr.indexOf('G') !== -1) num *= 1024;
                            if (sizeStr.indexOf('M') !== -1) num *= 1;
                            if (sizeStr.indexOf('K') !== -1) num /= 1024;
                            
                            if (num > maxVal) maxVal = num;
                            newFolders.push({ name: pathStr, sizeStr: sizeStr, rawSize: num });
                        }
                    }
                    
                    var finalModel = [];
                    for (var j = 0; j < newFolders.length; j++) {
                        finalModel.push({
                            name: newFolders[j].name,
                            size: newFolders[j].sizeStr,
                            relative: maxVal > 0 ? newFolders[j].rawSize / maxVal : 0
                        });
                    }
                    root.diskFolders = finalModel;
                }
            }
        }
    }

    Item {
        id: orientedRoot
        anchors.centerIn: parent
        width: (root.counterRotation % 180 !== 0) ? parent.height : parent.width
        height: (root.counterRotation % 180 !== 0) ? parent.width : parent.height
        rotation: root.counterRotation
        clip: false 

        StatTile {
            liquidWave: true
            active: root.widgetVisible
            wavePhase: root.globalWavePhase
            scaleFunc: root.s
            colorBase: root.cSurface0
            colorText: root.cText
            colorSubtext: root.cSubtext0
            colorCrust: root.cCrust
            iconFont: root.iconFont
            x: root.cellX(0.0)
            y: root.cellY(0.0)
            width: root.cellW(0.0, 0.333)
            height: root.cellH(0.0, 0.5)
            
            value: root.cpuUsage
            colorFill: Qt.lighter(root.cMauve, 1.4) 
            icon: "\uF2DB" 
            title: "CPU"
            valueText: Math.round(root.cpuUsage * 100) + "%"
        }

        StatTile {
            liquidWave: true
            active: root.widgetVisible
            wavePhase: root.globalWavePhase
            scaleFunc: root.s
            colorBase: root.cSurface0
            colorText: root.cText
            colorSubtext: root.cSubtext0
            colorCrust: root.cCrust
            iconFont: root.iconFont
            x: root.cellX(0.333)
            y: root.cellY(0.0)
            width: root.cellW(0.333, 0.334)
            height: root.cellH(0.0, 0.5)
            
            value: root.ramUsage
            colorFill: Qt.lighter(root.cMauve, 1.2) 
            icon: "\uF538" 
            title: "RAM"
            valueText: root.ramUsedGb.toFixed(1) + "G"
        }

        StatTile {
            liquidWave: true
            active: root.widgetVisible
            wavePhase: root.globalWavePhase
            scaleFunc: root.s
            colorBase: root.cSurface0
            colorText: root.cText
            colorSubtext: root.cSubtext0
            colorCrust: root.cCrust
            iconFont: root.iconFont
            x: root.cellX(0.667)
            y: root.cellY(0.0)
            width: root.cellW(0.667, 0.333)
            height: root.cellH(0.0, 0.5)
            
            value: Math.max(0.0, Math.min(1.0, root.tempC / 100.0))
            colorFill: root.cMauve 
            icon: "\uF2C9"
            title: "TEMP"
            valueText: Math.round(root.tempC) + "°"
        }

        StatTile {
            liquidWave: true
            active: root.widgetVisible
            wavePhase: root.globalWavePhase
            scaleFunc: root.s
            colorBase: root.cSurface0
            colorText: root.cText
            colorSubtext: root.cSubtext0
            colorCrust: root.cCrust
            iconFont: root.iconFont
            x: root.cellX(0.0)
            y: root.cellY(0.5)
            width: root.cellW(0.0, 0.5)
            height: root.cellH(0.5, 0.5)

            value: root.diskUsagePercent
            colorFill: Qt.darker(root.cMauve, 1.2) 
            icon: "\uF0A0"
            title: "DISK"
            subText: root.diskUsageText
            valueText: Math.round(root.diskUsagePercent * 100) + "%"
        }

        StatTile {
            liquidWave: true
            active: root.widgetVisible
            wavePhase: root.globalWavePhase
            scaleFunc: root.s
            colorBase: root.cSurface0
            colorText: root.cText
            colorSubtext: root.cSubtext0
            colorCrust: root.cCrust
            iconFont: root.iconFont
            x: root.cellX(0.5)
            y: root.cellY(0.5)
            width: root.cellW(0.5, 0.5)
            height: root.cellH(0.5, 0.5)
            
            value: 0.12 
            colorFill: Qt.darker(root.cMauve, 1.4) 
            icon: "󰤨"
            title: "NET"
            valueText: ""

            ColumnLayout {
                anchors.centerIn: parent
                spacing: root.s(15)

                RowLayout {
                    spacing: root.s(12)
                    Text { text: "\uF063"; font.family: root.iconFont; font.pixelSize: root.s(16); color: root.cGreen }
                    Text { text: root.rxSpeedStr; color: root.textPrimary; font.family: "JetBrains Mono"; font.pixelSize: root.s(16); font.bold: true }
                }

                RowLayout {
                    spacing: root.s(12)
                    Text { text: "\uF062"; font.family: root.iconFont; font.pixelSize: root.s(16); color: root.cPeach }
                    Text { text: root.txSpeedStr; color: root.textPrimary; font.family: "JetBrains Mono"; font.pixelSize: root.s(16); font.bold: true }
                }
            }
        }
    }
}
