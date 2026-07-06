import QtQuick
import QtQuick.Layouts

Item {
    id: tabScrollArea
    anchors.fill: parent

    property var scaleFunc: function(v) { return v; }
    function s(v) { return scaleFunc(v); }

    property real colSpacing: s(10)
    property real boxHeight: s(80)

    property alias flickable: flick
    property alias mainCol: mainCol
    default property alias content: mainCol.data

    function scrollTo(y) {
        let maxY = Math.max(0, flick.contentHeight - flick.height);
        flick.contentY = Math.max(0, Math.min(y - s(40), maxY > 0 ? maxY : y));
    }

    function scrollToBox(approxItemY) {
        let viewH = flick.height;
        let itemTop = approxItemY;
        let itemBottom = approxItemY + boxHeight;
        let curY = flick.contentY;
        let maxY = Math.max(0, flick.contentHeight - viewH);
        if (itemTop < curY + s(10)) {
            flick.contentY = Math.max(0, itemTop - s(20));
        } else if (itemBottom > curY + viewH - s(10)) {
            flick.contentY = Math.min(maxY, itemBottom - viewH + s(20));
        }
    }

    function scrollToBottom() {
        flick.contentY = Math.max(0, mainCol.implicitHeight - flick.height + s(100));
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: mainCol.implicitHeight + tabScrollArea.s(100)
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: mainCol
            width: flick.width
            spacing: tabScrollArea.colSpacing
        }
    }
}
