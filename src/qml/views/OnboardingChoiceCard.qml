import QtQuick
import QtQuick.Layouts

import Logos.Theme
import Logos.Controls

// One option in an either/or choice, as a card rather than a radio button. The
// routes through setup differ in what they commit the user to, not just in a
// value, so each needs room to say what picking it means.
LogosFrame {
    id: root

    property string title: ""
    property string description: ""
    property string badge: ""
    property bool selected: false
    // Shown under the title row, inside the card (e.g. the Custom URL field). Outside the
    // row's click area, so a field here takes its own clicks and typing.
    default property alias extra: extraColumn.data

    signal picked()

    Layout.fillWidth: true
    radius: Theme.spacing.radiusLarge
    backgroundColor: Theme.palette.surfaceRaised
    borderColor: Theme.palette.border
    padding: 0

    contentItem: Item {
        implicitWidth: row.implicitWidth + 2 * Theme.spacing.large
        implicitHeight: row.implicitHeight + 2 * Theme.spacing.large
                        + (extraColumn.visibleChildren.length > 0
                           ? extraColumn.implicitHeight + Theme.spacing.medium : 0)

        RowLayout {
            id: row
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Theme.spacing.large
            spacing: Theme.spacing.medium

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacing.small

                    LogosText {
                        text: root.title
                        color: Theme.palette.text
                        font.pixelSize: Theme.typography.primaryText
                        font.weight: Theme.typography.weightBold
                    }

                    LogosBadge {
                        visible: root.badge.length > 0
                        text: root.badge
                        color: Theme.palette.success
                    }

                    Item { Layout.fillWidth: true }
                }

                LogosText {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: root.description
                    color: Theme.palette.textSecondary
                    font.pixelSize: Theme.typography.secondaryText
                    wrapMode: Text.WordWrap
                }
            }

            LogosRadioButton {
                objectName: "choiceIndicator"
                Layout.alignment: Qt.AlignVCenter
                checked: root.selected
            }
        }

        MouseArea {
            anchors.fill: row
            anchors.margins: -Theme.spacing.large
            cursorShape: Qt.PointingHandCursor
            onClicked: root.picked()
        }

        ColumnLayout {
            id: extraColumn
            anchors.top: row.bottom
            anchors.topMargin: Theme.spacing.medium
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Theme.spacing.large
            anchors.rightMargin: Theme.spacing.large
            spacing: Theme.spacing.small
        }
    }
}
