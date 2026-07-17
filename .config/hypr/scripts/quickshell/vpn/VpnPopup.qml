import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
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

    property string activeMode: Config.mullvadEnabled ? "mullvad" : "tailscale"

    // --- Mullvad state ---
    property bool mvConnected: false
    property string mvState: "disconnected"
    property string mvCountry: ""
    property string mvCity: ""
    property bool mvBusy: false

    // --- Tailscale state ---
    property bool tsConnected: false
    property string tsState: "unknown"
    property string tsIp: ""
    property string tsHostname: ""
    property bool tsBusy: false

    readonly property bool connected: window.activeMode === "mullvad" ? window.mvConnected : window.tsConnected
    readonly property bool busy: window.activeMode === "mullvad" ? window.mvBusy : window.tsBusy

    readonly property string label: {
        if (window.activeMode === "mullvad") {
            if (window.mvBusy) return "Working...";
            if (window.mvState === "unavailable") return "Mullvad not installed";
            if (window.mvState === "connecting") return "Connecting...";
            if (window.mvState === "disconnecting") return "Disconnecting...";
            if (window.mvConnected) return "Connected";
            return "Disconnected";
        } else {
            if (window.tsBusy) return "Working...";
            if (window.tsState === "unavailable") return "Tailscale not installed";
            if (window.tsState === "NeedsLogin") return "Needs login";
            if (window.tsState === "Starting") return "Starting...";
            if (window.tsConnected) return "Connected";
            return "Disconnected";
        }
    }

    readonly property string locationLabel: {
        if (window.activeMode === "mullvad") {
            return window.mvCountry !== "" ? (window.mvCity !== "" ? window.mvCity + ", " + window.mvCountry : window.mvCountry) : "";
        } else {
            return window.tsIp !== "" ? window.tsIp : "";
        }
    }

    function refresh() {
        mvFetch.running = false;
        mvFetch.running = true;
        tsFetch.running = false;
        tsFetch.running = true;
    }

    Process {
        id: mvFetch
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/vpn_fetch.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt === "") return;
                try {
                    let data = JSON.parse(txt);
                    window.mvConnected = !!data.connected;
                    window.mvState = data.state || "disconnected";
                    window.mvCountry = data.country || "";
                    window.mvCity = data.city || "";
                } catch (e) {}
                window.mvBusy = false;
            }
        }
    }

    Process {
        id: tsFetch
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/tailscale_fetch.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt === "") return;
                try {
                    let data = JSON.parse(txt);
                    window.tsConnected = !!data.connected;
                    window.tsState = data.state || "unknown";
                    window.tsIp = data.ip || "";
                    window.tsHostname = data.hostname || "";
                } catch (e) {}
                window.tsBusy = false;
            }
        }
    }

    Process {
        id: toggleProcess
        stdout: StdioCollector { onStreamFinished: window.refresh() }
    }

    function toggleVpn() {
        if (window.activeMode === "mullvad") {
            if (window.mvBusy || window.mvState === "unavailable") return;
            window.mvBusy = true;
            toggleProcess.command = ["bash", "-c", window.mvConnected ? "mullvad disconnect" : "mullvad connect"];
        } else {
            if (window.tsBusy || window.tsState === "unavailable") return;
            window.tsBusy = true;
            toggleProcess.command = ["bash", "-c", window.tsConnected ? "tailscale down" : "tailscale up"];
        }
        toggleProcess.running = true;
    }

    Component.onCompleted: refresh()

    Rectangle {
        anchors.fill: parent
        radius: window.s(20)
        color: _theme.base
        border.color: _theme.surface0
        border.width: 1
        clip: true

        Column {
            id: content
            anchors.top: parent.top
            anchors.topMargin: window.s(26)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: window.s(16)
            width: parent.width - window.s(48)

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: window.activeMode === "mullvad" ? "MULLVAD" : "TAILSCALE"
                font.family: "JetBrains Mono"
                font.weight: Font.Black
                font.pixelSize: window.s(14)
                color: _theme.subtext0
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: window.s(64)
                height: window.s(64)
                radius: width / 2
                color: window.connected ? Qt.rgba(_theme.green.r, _theme.green.g, _theme.green.b, 0.18) : Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.06)
                border.width: 2
                border.color: window.connected ? _theme.green : _theme.overlay0
                Behavior on color { ColorAnimation { duration: 300 } }
                Behavior on border.color { ColorAnimation { duration: 300 } }

                Text {
                    anchors.centerIn: parent
                    text: window.activeMode === "mullvad" ? "󰖂" : "󱗼"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: window.s(28)
                    color: window.connected ? _theme.green : _theme.overlay0
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: window.label
                font.family: "JetBrains Mono"
                font.weight: Font.Black
                font.pixelSize: window.s(18)
                color: _theme.text
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: window.locationLabel
                visible: text !== ""
                font.family: "JetBrains Mono"
                font.pixelSize: window.s(12)
                color: _theme.subtext0
            }

            ActionButton {
                anchors.horizontalCenter: parent.horizontalCenter
                width: window.s(160)
                height: window.s(38)
                radius: window.s(12)
                enabled: window.label.indexOf("not installed") === -1 && window.label !== "Needs login" && !window.busy
                opacity: enabled ? 1.0 : 0.5

                theme: _theme
                scaleFunc: window.s
                label: window.connected ? "Disconnect" : "Connect"
                labelSize: 14
                fontWeight: Font.Black
                accentColor: window.connected ? _theme.red : _theme.green
                onClicked: window.toggleVpn()
            }
        }

        HorizontalTabBar {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: window.s(20)
            width: parent.width - window.s(48)
            height: window.s(48)
            visible: Config.mullvadEnabled && Config.tailscaleEnabled
            theme: _theme
            scaleFunc: window.s
            accentColor: _theme.green
            tabs: [
                { tabId: "mullvad", icon: "󰖂", label: "Mullvad" },
                { tabId: "tailscale", icon: "󱗼", label: "Tailscale" }
            ]
            activeTab: window.activeMode
            onTabSelected: (tabId) => window.activeMode = tabId
        }
    }
}
