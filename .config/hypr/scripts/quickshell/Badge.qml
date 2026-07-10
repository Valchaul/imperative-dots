import QtQuick
import QtQuick.Layouts

Rectangle {
    id: badge

    property var scaleFunc: function(v) { return v; }
    function s(v) { return scaleFunc(v); }

    property string text: ""
    property color accentColor: "#cba6f7"
    property real bgAlpha: 0.15
    property real fontSize: 9
    property real paddingH: 12
    property real heightHint: 19
    property bool bold: true
    property bool uppercase: false
    property string fontFamily: "JetBrains Mono"
    property real borderAlpha: 0
    property real radiusHint: 6

    Layout.preferredHeight: s(heightHint)
    Layout.preferredWidth: badgeText.implicitWidth + s(paddingH)
    implicitHeight: s(heightHint)
    implicitWidth: badgeText.implicitWidth + s(paddingH)
    radius: s(radiusHint)
    color: Qt.alpha(accentColor, bgAlpha)
    border.color: Qt.alpha(accentColor, borderAlpha)
    border.width: borderAlpha > 0 ? 1 : 0

    Text {
        id: badgeText
        anchors.centerIn: parent
        text: badge.uppercase ? badge.text.toUpperCase() : badge.text
        font.family: badge.fontFamily
        font.weight: badge.bold ? Font.Bold : Font.Normal
        font.pixelSize: badge.s(badge.fontSize)
        color: badge.accentColor
    }
}
