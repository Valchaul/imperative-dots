import QtQuick

// Extracted from the "LiquidSquare" tile duplicated between SystemUsage.qml
// (full popup) and SystemUsageLight.qml (sidebar widget). Those two were NOT
// accidental copies - the light version deliberately swaps the animated wave
// Canvas for a static Behavior-animated fill, because a continuously
// repainting Canvas in a widget that's always on screen would itself burn
// CPU and skew the very CPU% reading being displayed. That distinction is
// preserved here via `liquidWave` - default true (full wave animation),
// set false for the cheap static-fill mode.
Item {
    id: tile

    property var scaleFunc: function(v) { return v; }
    function s(v) { return scaleFunc(v); }
    function alpha(color, a) { return Qt.rgba(color.r, color.g, color.b, a); }

    property color colorBase: "#313244"
    property color colorFill: "#cba6f7"
    property color colorText: "#cdd6f4"
    property color colorSubtext: "#a6adc8"
    property color colorCrust: "#11111b"
    property string iconFont: "Iosevka Nerd Font"

    property real value: 0.0
    property string icon: ""
    property string title: ""
    property string valueText: ""
    property string subText: ""

    // true: animated wavy liquid surface (Canvas, continuous repaint while
    // filled). false: plain rectangle fill that just animates its height.
    property bool liquidWave: true
    property bool active: true // gates the wave repaint loop when off-screen

    default property alias childItems: customContent.data

    property real fillRatio: Math.max(0.0, Math.min(1.0, tile.value))
    property real fillY: height * (1.0 - fillRatio)

    property real wavePhase: 0
    NumberAnimation on wavePhase {
        running: tile.liquidWave && tile.active && tile.value > 0
        from: 0; to: Math.PI * 2; duration: 3000; loops: Animation.Infinite
    }
    property real waveAmp: (liquidWave && fillRatio < 0.99 && fillRatio > 0.01) ? s(6) * Math.sin(fillRatio * Math.PI) : 0

    Rectangle {
        anchors.fill: parent
        radius: tile.s(12)
        color: tile.colorBase
        border.color: tile.alpha(tile.colorText, 0.08)
        border.width: 1
        clip: !tile.liquidWave
    }

    // Static fill mode (light/cheap)
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: !tile.liquidWave && tile.value > 0
        height: parent.height * tile.fillRatio
        radius: tile.s(12)
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(tile.colorFill, 1.25) }
            GradientStop { position: 1.0; color: tile.colorFill }
        }
        Behavior on height { NumberAnimation { duration: 800; easing.type: Easing.OutQuint } }
    }

    // Animated wave fill mode (full)
    Canvas {
        id: fluidCanvas
        anchors.fill: parent
        visible: tile.liquidWave
        onPaint: {
            let ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            if (tile.value <= 0) return;

            ctx.save();

            let r = tile.s(12);
            ctx.beginPath();
            ctx.moveTo(r, 0);
            ctx.lineTo(width - r, 0);
            ctx.quadraticCurveTo(width, 0, width, r);
            ctx.lineTo(width, height - r);
            ctx.quadraticCurveTo(width, height, width - r, height);
            ctx.lineTo(r, height);
            ctx.quadraticCurveTo(0, height, 0, height - r);
            ctx.lineTo(0, r);
            ctx.quadraticCurveTo(0, 0, r, 0);
            ctx.closePath();
            ctx.clip();

            ctx.beginPath();
            ctx.moveTo(0, tile.fillY);
            if (tile.waveAmp > 0) {
                let cp1y = tile.fillY + Math.sin(tile.wavePhase) * tile.waveAmp;
                let cp2y = tile.fillY + Math.cos(tile.wavePhase + Math.PI) * tile.waveAmp;
                ctx.bezierCurveTo(width * 0.33, cp2y, width * 0.66, cp1y, width, tile.fillY);
                ctx.lineTo(width, height);
                ctx.lineTo(0, height);
            } else {
                ctx.lineTo(width, tile.fillY);
                ctx.lineTo(width, height);
                ctx.lineTo(0, height);
            }
            ctx.closePath();

            let grad = ctx.createLinearGradient(0, 0, 0, height);
            grad.addColorStop(0, Qt.lighter(tile.colorFill, 1.25).toString());
            grad.addColorStop(1, tile.colorFill.toString());
            ctx.fillStyle = grad;
            ctx.globalAlpha = 0.95;
            ctx.fill();
            ctx.restore();
        }
        Connections {
            target: tile
            enabled: tile.liquidWave
            function onWavePhaseChanged() { fluidCanvas.requestPaint(); }
            function onValueChanged() { fluidCanvas.requestPaint(); }
        }
        Component.onCompleted: requestPaint()
    }

    Item {
        anchors.fill: parent
        anchors.margins: tile.s(12)

        Text {
            id: baseIcon
            anchors.top: parent.top
            anchors.left: parent.left
            font.family: tile.iconFont; font.pixelSize: tile.s(16)
            color: tile.colorSubtext; text: tile.icon
        }
        Text {
            anchors.verticalCenter: baseIcon.verticalCenter
            anchors.right: parent.right
            font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: tile.s(10)
            color: tile.colorSubtext; text: tile.title
        }
        Text {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.bottomMargin: tile.s(4)
            font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: tile.s(12)
            color: tile.colorSubtext; text: tile.subText
        }
        Text {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: tile.s(24)
            color: tile.colorText; text: tile.valueText
        }
    }

    // Re-rendered on top of the fill, clipped to the filled height, so text
    // over the colored fill reads in a contrasting (crust) color while text
    // over the empty background stays dim (subtext) - the "liquid level" look.
    Item {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.min(parent.height, parent.height * tile.fillRatio)
        clip: true
        visible: tile.value > 0

        Item {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: tile.height
            anchors.margins: tile.s(12)

            Text {
                id: filledIcon
                anchors.top: parent.top
                anchors.left: parent.left
                font.family: tile.iconFont; font.pixelSize: tile.s(16)
                color: tile.alpha(tile.colorCrust, 0.7); text: tile.icon
            }
            Text {
                anchors.verticalCenter: filledIcon.verticalCenter
                anchors.right: parent.right
                font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: tile.s(10)
                color: tile.alpha(tile.colorCrust, 0.7); text: tile.title
            }
            Text {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.bottomMargin: tile.s(4)
                font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: tile.s(12)
                color: tile.colorCrust; text: tile.subText
            }
            Text {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: tile.s(24)
                color: tile.colorCrust; text: tile.valueText
            }
        }
    }

    Item {
        id: customContent
        anchors.fill: parent
        anchors.margins: tile.s(12)
        z: 10
    }
}
