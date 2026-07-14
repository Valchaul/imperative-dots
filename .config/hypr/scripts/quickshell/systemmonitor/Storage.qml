import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: root

    function s(val) { return typeof scaleFunc === "function" ? scaleFunc(val) : val; }
    property color cBase: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.base : "#1e1e2e"
    property color cText: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.text : "#cdd6f4"
    property color cSubtext0: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.subtext0 : "#a6adc8"
    property color cSurface0: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.surface0 : "#313244"
    property color cSurface1: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.surface1 : "#45475a"
    property color cMauve: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.mauve : "#cba6f7"
    property color cRed: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.red : "#f38ba8"
    property color cBlue: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.blue : "#89b4fa"
    property color cPeach: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.peach : "#fab387"
    property color cGreen: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.green : "#a6e3a1"
    property color cYellow: typeof mochaColors !== "undefined" && mochaColors ? mochaColors.yellow : "#f9e2af"

    property bool active: parent !== null && parent.visible !== undefined ? parent.visible : true
    property var drives: []

    function kindColor(kind) {
        if (kind === "hdd") return root.cMauve;
        if (kind === "nvme") return root.cBlue;
        if (kind === "usb") return root.cPeach;
        if (kind === "sd") return root.cYellow;
        return root.cGreen; // sata/other ssd
    }

    function fmtBytes(b) {
        if (!b || b <= 0) return "0 GB";
        let units = ["B", "KB", "MB", "GB", "TB"];
        let i = Math.min(units.length - 1, Math.floor(Math.log(b) / Math.log(1024)));
        return (b / Math.pow(1024, i)).toFixed(i === 0 ? 0 : 1) + " " + units[i];
    }

    Timer {
        id: refreshTimer
        interval: 5000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: { fetchProc.running = false; fetchProc.running = true; }
    }

    Process {
        id: fetchProc
        command: ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/systemmonitor/storage_fetch.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                let text = this.text ? this.text.trim() : "";
                if (!text) { root.drives = []; return; }

                let newDrives = [];
                let lines = text.split("\n");
                for (let i = 0; i < lines.length; i++) {
                    let parts = lines[i].split("\x1f");
                    if (parts.length < 6) continue;

                    let rawSize = parseFloat(parts[3]) || 0;
                    let fsTotal = parseFloat(parts[5]) || 0;
                    let used = parseFloat(parts[4]) || 0;
                    let total = fsTotal > 0 ? fsTotal : rawSize;

                    newDrives.push({
                        name: parts[0],
                        kind: parts[1],
                        model: parts[2],
                        used: used,
                        total: total,
                        pct: total > 0 ? (used / total * 100) : 0,
                        mountpoint: parts.length > 6 ? parts[6] : ""
                    });
                }
                root.drives = newDrives;
            }
        }
    }

    ScrollView {
        anchors.fill: parent
        clip: true
        ScrollBar.vertical: ScrollBar {}

        Flow {
            x: root.s(20)
            y: root.s(20)
            width: root.width - root.s(40)
            spacing: root.s(24)

            Repeater {
                model: root.drives

                delegate: HoverCard {
                    id: driveCard
                    width: root.s(214)
                    height: root.s(304)
                    theme: root
                    scaleFunc: root.s
                    radius: root.s(16)
                    baseColor: root.cSurface0
                    accentColor: root.kindColor(modelData.kind)
                    borderColorNormal: root.cSurface1
                    pressScale: 1.0
                    clickable: modelData.mountpoint !== ""

                    // Opens the drive's mount point in the file manager and closes this
                    // popup.
                    onClicked: {
                        Quickshell.execDetached(["nautilus", modelData.mountpoint]);
                        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: root.s(14)
                        spacing: root.s(10)

                        // ── Illustration ──────────────────────────────
                        Item {
                            Layout.preferredWidth: root.s(124)
                            Layout.preferredHeight: root.s(166)
                            Layout.alignment: Qt.AlignHCenter

                            // HDD: spinning-platter pie chart + swinging read/write head
                            Item {
                                anchors.fill: parent
                                visible: modelData.kind === "hdd"

                                // Drive case, sitting behind the platter
                                Rectangle {
                                    anchors.fill: parent
                                    radius: root.s(10)
                                    color: Qt.lighter(root.cSurface1, 1.2)
                                    border.color: Qt.alpha(root.cText, 0.08)
                                    border.width: 1
                                }

                                Canvas {
                                    id: platterCanvas
                                    anchors.top: parent.top
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.topMargin: root.s(9)
                                    width: parent.width - root.s(18)
                                    height: width
                                    property real pct: modelData.pct || 0
                                    property color usedColor: root.kindColor(modelData.kind)
                                    onPctChanged: requestPaint()
                                    onUsedColorChanged: requestPaint()
                                    onPaint: {
                                        let ctx = getContext("2d");
                                        ctx.reset();
                                        let cx = width / 2, cy = height / 2, r = width / 2 - 2;

                                        ctx.beginPath();
                                        ctx.arc(cx, cy, r, 0, Math.PI * 2);
                                        ctx.fillStyle = Qt.darker(root.cSurface0, 1.4);
                                        ctx.fill();

                                        let usedAngle = (Math.max(0, Math.min(100, pct)) / 100) * Math.PI * 2;
                                        ctx.beginPath();
                                        ctx.moveTo(cx, cy);
                                        ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + usedAngle);
                                        ctx.closePath();
                                        ctx.fillStyle = usedColor;
                                        ctx.fill();

                                        ctx.strokeStyle = Qt.alpha(root.cText, 0.08);
                                        ctx.lineWidth = 1;
                                        for (let gr = r * 0.42; gr < r; gr += r * 0.22) {
                                            ctx.beginPath();
                                            ctx.arc(cx, cy, gr, 0, Math.PI * 2);
                                            ctx.stroke();
                                        }

                                        ctx.beginPath();
                                        ctx.arc(cx, cy, r * 0.14, 0, Math.PI * 2);
                                        ctx.fillStyle = root.cSurface1;
                                        ctx.fill();
                                    }
                                    Component.onCompleted: requestPaint()
                                }

                                Image {
                                    id: headArm
                                    source: "hdd-head.png"
                                    width: parent.width * 0.92
                                    height: width
                                    anchors.left: parent.left
                                    anchors.bottom: parent.bottom
                                    anchors.leftMargin: -width * 0.1
                                    anchors.bottomMargin: -height * 0.22
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    transform: Rotation {
                                        origin.x: headArm.width * 0.5
                                        origin.y: headArm.height * 0.61
                                        angle: -16
                                    }
                                    SequentialAnimation on rotation {
                                        running: root.active
                                        loops: Animation.Infinite
                                        NumberAnimation { from: -16; to: 6; duration: 1600; easing.type: Easing.InOutSine }
                                        PauseAnimation { duration: 300 }
                                        NumberAnimation { from: 6; to: -16; duration: 1600; easing.type: Easing.InOutSine }
                                        PauseAnimation { duration: 300 }
                                    }
                                }
                            }

                            // NVMe / plain SSD: M.2 stick with gold edge connector + a memory
                            // chip that fills bottom-up as the drive fills up.
                            Canvas {
                                id: nvmeCanvas
                                anchors.fill: parent
                                visible: modelData.kind === "nvme" || modelData.kind === "ssd"
                                property real pct: modelData.pct || 0
                                property color accent: root.kindColor(modelData.kind)
                                onPctChanged: requestPaint()
                                onAccentChanged: requestPaint()
                                onPaint: {
                                    let ctx = getContext("2d");
                                    ctx.reset();

                                    let stickW = width * 0.34;
                                    let stickH = height * 0.86;
                                    let stickX = (width - stickW) / 2;
                                    let stickY = height * 0.02;

                                    // PCB body
                                    let pcbColor = Qt.lighter(root.cSurface1, 1.2);
                                    ctx.fillStyle = pcbColor;
                                    ctx.fillRect(stickX, stickY, stickW, stickH);
                                    ctx.strokeStyle = Qt.alpha(root.cText, 0.12);
                                    ctx.lineWidth = 1;
                                    ctx.strokeRect(stickX, stickY, stickW, stickH);

                                    // Gold edge-connector fingers at the bottom, with a keying notch
                                    let connH = stickH * 0.07;
                                    let connY = stickY + stickH - connH;
                                    ctx.fillStyle = "#d4af37";
                                    ctx.fillRect(stickX, connY, stickW, connH);
                                    let notchW = stickW * 0.16;
                                    let notchX = stickX + stickW * 0.28;
                                    ctx.fillStyle = pcbColor;
                                    ctx.fillRect(notchX, connY, notchW, connH);

                                    // Memory chip, outlined, fills bottom-up with used%
                                    let chipW = stickW * 0.72;
                                    let chipH = stickH * 0.38;
                                    let chipX = stickX + (stickW - chipW) / 2;
                                    let chipY = stickY + stickH * 0.18;

                                    ctx.fillStyle = Qt.darker(root.cSurface0, 1.2);
                                    ctx.fillRect(chipX, chipY, chipW, chipH);

                                    let fillH = chipH * Math.max(0, Math.min(100, pct)) / 100;
                                    ctx.fillStyle = accent;
                                    ctx.fillRect(chipX, chipY + chipH - fillH, chipW, fillH);

                                    ctx.strokeStyle = Qt.alpha(root.cText, 0.25);
                                    ctx.lineWidth = 1;
                                    ctx.strokeRect(chipX, chipY, chipW, chipH);
                                }
                                Component.onCompleted: requestPaint()
                            }

                            // USB: capsule body + silver shroud + blade connector, body
                            // fills bottom-up with used%.
                            Canvas {
                                id: usbCanvas
                                anchors.fill: parent
                                visible: modelData.kind === "usb"
                                property real pct: modelData.pct || 0
                                property color accent: root.kindColor(modelData.kind)
                                onPctChanged: requestPaint()
                                onAccentChanged: requestPaint()
                                onPaint: {
                                    let ctx = getContext("2d");
                                    ctx.reset();

                                    let bodyW = width * 0.4;
                                    let bodyH = height * 0.56;
                                    let bodyX = (width - bodyW) / 2;
                                    let bodyY = height * 0.04;
                                    let r = bodyW * 0.12;

                                    function roundedBody(ctx) {
                                        ctx.beginPath();
                                        ctx.moveTo(bodyX + r, bodyY);
                                        ctx.arcTo(bodyX + bodyW, bodyY, bodyX + bodyW, bodyY + bodyH, r);
                                        ctx.arcTo(bodyX + bodyW, bodyY + bodyH, bodyX, bodyY + bodyH, r);
                                        ctx.arcTo(bodyX, bodyY + bodyH, bodyX, bodyY, r);
                                        ctx.arcTo(bodyX, bodyY, bodyX + bodyW, bodyY, r);
                                        ctx.closePath();
                                    }

                                    // Body casing (base)
                                    roundedBody(ctx);
                                    ctx.fillStyle = Qt.lighter(root.cSurface1, 1.2);
                                    ctx.fill();

                                    // Fill gauge inside the body, bottom-up
                                    ctx.save();
                                    roundedBody(ctx);
                                    ctx.clip();
                                    let fillH = bodyH * Math.max(0, Math.min(100, pct)) / 100;
                                    ctx.fillStyle = accent;
                                    ctx.fillRect(bodyX, bodyY + bodyH - fillH, bodyW, fillH);

                                    // Subtle plastic sheen down the left side
                                    ctx.fillStyle = Qt.alpha("#ffffff", 0.08);
                                    ctx.fillRect(bodyX + bodyW * 0.16, bodyY, bodyW * 0.16, bodyH);
                                    ctx.restore();

                                    roundedBody(ctx);
                                    ctx.strokeStyle = Qt.alpha(root.cText, 0.12);
                                    ctx.lineWidth = 1;
                                    ctx.stroke();

                                    // Lanyard hole near the top
                                    ctx.beginPath();
                                    ctx.arc(bodyX + bodyW / 2, bodyY + bodyH * 0.16, bodyW * 0.11, 0, Math.PI * 2);
                                    ctx.fillStyle = Qt.darker(root.cSurface0, 1.3);
                                    ctx.fill();
                                    ctx.strokeStyle = Qt.alpha("#000000", 0.2);
                                    ctx.lineWidth = 1;
                                    ctx.stroke();

                                    // Silver shroud collar
                                    let shroudW = bodyW * 0.68;
                                    let shroudH = height * 0.07;
                                    let shroudX = (width - shroudW) / 2;
                                    let shroudY = bodyY + bodyH;
                                    ctx.fillStyle = "#c4c4cc";
                                    ctx.fillRect(shroudX, shroudY, shroudW, shroudH);

                                    // Metal blade connector
                                    let bladeW = shroudW * 0.8;
                                    let bladeH = height * 0.14;
                                    let bladeX = (width - bladeW) / 2;
                                    let bladeY = shroudY + shroudH;
                                    ctx.fillStyle = "#a8a8b2";
                                    ctx.fillRect(bladeX, bladeY, bladeW, bladeH);
                                    ctx.strokeStyle = Qt.alpha("#000000", 0.25);
                                    ctx.beginPath();
                                    ctx.moveTo(bladeX + bladeW / 2, bladeY + bladeH * 0.1);
                                    ctx.lineTo(bladeX + bladeW / 2, bladeY + bladeH * 0.9);
                                    ctx.stroke();
                                }
                                Component.onCompleted: requestPaint()
                            }

                            // SD card: cut-corner card body + gold contact pins along the
                            // top edge (same side as the bevel), body fills bottom-up
                            // (below the pins) with used%.
                            Canvas {
                                id: sdCanvas
                                anchors.fill: parent
                                visible: modelData.kind === "sd"
                                property real pct: modelData.pct || 0
                                property color accent: root.kindColor(modelData.kind)
                                onPctChanged: requestPaint()
                                onAccentChanged: requestPaint()
                                onPaint: {
                                    let ctx = getContext("2d");
                                    ctx.reset();

                                    let cardW = width * 0.86;
                                    let cardH = height * 0.88;
                                    let cardX = (width - cardW) / 2;
                                    let cardY = height * 0.02;
                                    let bevel = cardW * 0.22;

                                    function cardPath() {
                                        ctx.beginPath();
                                        ctx.moveTo(cardX, cardY);
                                        ctx.lineTo(cardX + cardW - bevel, cardY);
                                        ctx.lineTo(cardX + cardW, cardY + bevel);
                                        ctx.lineTo(cardX + cardW, cardY + cardH);
                                        ctx.lineTo(cardX, cardY + cardH);
                                        ctx.closePath();
                                    }

                                    // Body
                                    cardPath();
                                    ctx.fillStyle = Qt.lighter(root.cSurface1, 1.2);
                                    ctx.fill();

                                    // Gold contact pins along the top edge, clipped to the
                                    // card silhouette so the beveled corner overlaps/cuts
                                    // into the last pin rather than sitting clear of it
                                    let pinAreaH = cardH * 0.16;
                                    let pinAreaY = cardY;
                                    let pinCount = 8;
                                    let pinGap = cardW * 0.02;
                                    let pinW = (cardW - pinGap * (pinCount + 1)) / pinCount;
                                    ctx.save();
                                    cardPath();
                                    ctx.clip();
                                    ctx.fillStyle = "#d4af37";
                                    for (let i = 0; i < pinCount; i++) {
                                        let px = cardX + pinGap + i * (pinW + pinGap);
                                        ctx.fillRect(px, pinAreaY, pinW, pinAreaH);
                                    }
                                    ctx.restore();

                                    // Fill gauge below the pins, bottom-up with used%
                                    let gaugeY = pinAreaY + pinAreaH + cardH * 0.06;
                                    let gaugeH = (cardY + cardH) - cardH * 0.08 - gaugeY;
                                    let gaugeW = cardW * 0.7;
                                    let gaugeX = cardX + (cardW - gaugeW) / 2;
                                    ctx.fillStyle = Qt.darker(root.cSurface0, 1.2);
                                    ctx.fillRect(gaugeX, gaugeY, gaugeW, gaugeH);

                                    let fillH = gaugeH * Math.max(0, Math.min(100, pct)) / 100;
                                    ctx.fillStyle = accent;
                                    ctx.fillRect(gaugeX, gaugeY + gaugeH - fillH, gaugeW, fillH);

                                    ctx.strokeStyle = Qt.alpha(root.cText, 0.25);
                                    ctx.lineWidth = 1;
                                    ctx.strokeRect(gaugeX, gaugeY, gaugeW, gaugeH);

                                    // Write-protect notch on the left edge
                                    ctx.fillStyle = Qt.darker(root.cSurface0, 1.4);
                                    ctx.fillRect(cardX, cardY + cardH * 0.6, cardW * 0.06, cardH * 0.08);

                                    // Outline
                                    cardPath();
                                    ctx.strokeStyle = Qt.alpha(root.cText, 0.12);
                                    ctx.lineWidth = 1;
                                    ctx.stroke();
                                }
                                Component.onCompleted: requestPaint()
                            }
                        }

                        // ── Info ───────────────────────────────────────
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: root.s(3)

                            Text {
                                Layout.fillWidth: true
                                text: modelData.model
                                font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(14)
                                color: root.cText
                                elide: Text.ElideRight
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: root.s(6)

                                Text {
                                    Layout.fillWidth: true
                                    text: "/dev/" + modelData.name
                                    font.family: "JetBrains Mono"; font.pixelSize: root.s(11)
                                    color: root.cSubtext0
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: modelData.kind.toUpperCase()
                                    font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(10)
                                    color: root.kindColor(modelData.kind)
                                }
                            }

                            Row {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    text: root.fmtBytes(modelData.used)
                                    font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(11)
                                    color: root.kindColor(modelData.kind)
                                }
                                Text {
                                    text: " / " + root.fmtBytes(modelData.total)
                                    font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(11)
                                    color: root.cSubtext0
                                }
                            }

                            // Eject button - removable media only (USB / SD card). Same
                            // gradient-filled pod look as the top bar's status pills
                            // (e.g. the bluetooth pill), permanently "active" so its
                            // accent-colored gradient always shows.
                            StatusPill {
                                id: ejectPill
                                visible: modelData.kind === "usb" || modelData.kind === "sd"
                                Layout.topMargin: root.s(4)
                                Layout.alignment: Qt.AlignHCenter
                                theme: root
                                scaleFunc: root.s
                                height: root.s(28)
                                contentAlignment: "center"
                                introTrigger: true
                                active: true
                                activeColorStart: root.kindColor(modelData.kind)
                                enabled: !ejectProc.running

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: ""
                                    font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(14)
                                    color: root.cBase
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: ejectProc.running ? "Ejecting…" : "Eject"
                                    font.family: "JetBrains Mono"; font.pixelSize: root.s(11); font.weight: Font.Black
                                    color: root.cBase
                                }

                                Process {
                                    id: ejectProc
                                    command: ["udisksctl", "power-off", "-b", "/dev/" + modelData.name]
                                }

                                onClicked: { ejectProc.running = false; ejectProc.running = true; }
                            }
                        }
                    }
                }
            }

            Text {
                visible: root.drives.length === 0
                text: "No storage devices detected"
                font.family: "JetBrains Mono"; font.pixelSize: root.s(13)
                color: root.cSubtext0
            }
        }
    }
}
