import QtQuick
import QtQuick.Layouts

// Text input box whose border/background lights up on focus. Used by
// SettingsPopup.qml's wallpaper/language search fields, the wifi password
// field in NetworkPopup.qml, and MovieWidget.qml's search field.
Rectangle {
    id: focusInput

    property var theme
    property var scaleFunc: function(v) { return v; }
    function s(v) { return scaleFunc(v); }

    property alias text: input.text
    property alias inputItem: input
    property string placeholder: ""
    property color accentColor: theme ? theme.mauve : "#cba6f7"
    property color normalBorderColor: theme ? theme.surface2 : "#585b70"
    property color textColor: theme ? theme.text : "#cdd6f4"
    property color placeholderColor: theme ? theme.subtext0 : "#a6adc8"
    property color normalBgColor: theme ? theme.surface0 : "#313244"
    // Optional tint while focused - defaults to normalBgColor, i.e. no change.
    property color focusBgColor: normalBgColor
    property string fontFamily: "JetBrains Mono"
    property real fontSize: 11
    property bool selectByMouse: true
    property var validator: null
    property int echoMode: TextInput.Normal
    property real hMargin: 9

    signal accepted()
    signal editingFinished()
    signal escapePressed()

    Layout.fillWidth: true
    Layout.preferredHeight: s(34)
    radius: s(7)
    color: input.activeFocus ? focusBgColor : normalBgColor
    border.color: input.activeFocus ? accentColor : normalBorderColor
    border.width: 1
    Behavior on border.color { ColorAnimation { duration: 200 } }
    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: focusInput.s(focusInput.hMargin)
        anchors.rightMargin: focusInput.s(focusInput.hMargin)
        anchors.topMargin: focusInput.s(6)
        anchors.bottomMargin: focusInput.s(6)
        verticalAlignment: TextInput.AlignVCenter
        font.family: focusInput.fontFamily
        font.pixelSize: focusInput.s(focusInput.fontSize)
        color: focusInput.textColor
        clip: true
        selectByMouse: focusInput.selectByMouse
        echoMode: focusInput.echoMode
        validator: focusInput.validator
        onAccepted: focusInput.accepted()
        onEditingFinished: focusInput.editingFinished()
        Keys.onEscapePressed: (event) => { focusInput.escapePressed(); event.accepted = false; }

        Text {
            text: focusInput.placeholder
            color: focusInput.placeholderColor
            visible: !input.text && !input.activeFocus
            font: input.font
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
