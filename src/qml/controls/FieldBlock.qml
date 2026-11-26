import QtQuick
import QtQuick.Layouts

import Logos.Theme
import Logos.Controls

// One field of a form on its own rounded panel, its label on top in the style of a selected
// type pill: bold, in the main text colour. Send and Bridge use it for From, To and Amount.
Rectangle {
    id: root

    property string label: ""
    // The label's size: the selected type pill's on Send, so the two read as one style.
    property int labelPixelSize: Theme.typography.primaryText
    default property alias content: blockColumn.data

    Layout.fillWidth: true
    radius: 6
    color: Theme.palette.backgroundSecondary
    implicitHeight: blockColumn.implicitHeight + 2 * Theme.spacing.medium

    ColumnLayout {
        id: blockColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacing.medium
        spacing: Theme.spacing.small

        LogosText {
            text: root.label
            color: Theme.palette.text
            font.pixelSize: root.labelPixelSize
            font.weight: Theme.typography.weightBold
        }
    }
}
