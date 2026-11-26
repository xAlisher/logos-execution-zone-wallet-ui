import QtQuick
import QtQuick.Layouts

import Logos.Theme

// A tab's content: one column capped at 560 and centred, as in the Ethereum, Keycard and
// Signer apps. Children stack in it; one with Layout.fillHeight takes the rest.
Item {
    id: root
    default property alias content: column.data
    property int maxWidth: 560

    ColumnLayout {
        id: column
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.spacing.large
        anchors.bottomMargin: Theme.spacing.large
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(root.maxWidth, root.width - 2 * Theme.spacing.xlarge)
        spacing: Theme.spacing.medium
    }
}
