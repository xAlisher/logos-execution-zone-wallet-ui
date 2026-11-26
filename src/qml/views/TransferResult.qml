import QtQuick
import QtQuick.Layouts

import Logos.Theme
import Logos.Controls

// Under Send and Bridge: the proof while it is made, then the outcome, with the sent
// transaction one click away in the Explorer.
ColumnLayout {
    id: root

    property string transferResult: ""
    property string transferTxHash: ""
    property bool transferResultIsError: false
    property bool transferPending: false

    signal viewInExplorerRequested(string txHash)

    spacing: Theme.spacing.small

    RowLayout {
        Layout.fillWidth: true
        visible: root.transferPending
        spacing: Theme.spacing.small

        LogosSpinner {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            running: root.transferPending
        }
        LogosText {
            Layout.fillWidth: true
            text: qsTr("Generating proof, please wait…")
            font.pixelSize: Theme.typography.secondaryText
            color: Theme.palette.textSecondary
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: !root.transferPending && root.transferResult.length > 0
        LogosCopyableText {
            Layout.fillWidth: true
            text: root.transferResult
            copyText: root.transferTxHash || root.transferResult
            textColor: root.transferResultIsError ? Theme.palette.error : Theme.palette.textSecondary
            showCopyButton: true
        }
        LogosButton {
            objectName: "lezViewTxInExplorerButton"
            visible: !root.transferResultIsError && root.transferTxHash.length > 0
            compact: true
            text: qsTr("View in explorer")
            onClicked: root.viewInExplorerRequested(root.transferTxHash)
        }
    }
}
