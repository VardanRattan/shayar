pragma ComponentBehavior: Bound
import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property bool skipIntroAnimation
    property color topColour: config.primary || "#68779b"
    property color bottomColour: config.text || "#e3e5f0"

    implicitWidth: 128
    implicitHeight: 128

    Item {
        id: logo
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width

        Image {
            id: shayarImg
            anchors.fill: parent
            source: Qt.resolvedUrl("../assets/shayar.svg")
            sourceSize.width: width * 2
            sourceSize.height: height * 2
            smooth: true
            mipmap: true
            fillMode: Image.PreserveAspectFit
            visible: true
        }

        ColorOverlay {
            anchors.fill: shayarImg
            source: shayarImg
            color: root.topColour
        }
    }
}
