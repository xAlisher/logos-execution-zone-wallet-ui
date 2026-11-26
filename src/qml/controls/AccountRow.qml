import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Logos.Theme
import Logos.Controls
import Logos.Icons
import "../Base58.js" as Base58
import "../Format.js" as Format
import "../Units.js" as Units

// One account on the Accounts tab, laid out as the Keycard and Signer apps lay out an account
// (accountkit's AccountDetails): a rounded row, the name in bold with the edit pencil beside
// it, then labelled lines in small text with mono values and copy buttons. The balance sits at
// the right, as the Ethereum wallet shows a token's. A private account adds its keys line: the
// pair someone needs to send to it privately.
Rectangle {
    id: root

    property string name: ""
    property string accountId: ""
    property string balance: ""
    property bool isPublic: true
    property string keysJson: ""

    signal labelRequested(string accountId, bool isPublic)
    signal viewInExplorerRequested(string accountIdBase58)
    // A click on the row itself (not on one of its buttons): open the account's page.
    signal opened()

    readonly property string address: Base58.encode(root.accountId)
    readonly property var keys: {
        try { return JSON.parse(root.keysJson || "{}") } catch (e) { return {} }
    }

    implicitHeight: layout.implicitHeight + 2 * Theme.spacing.small
    radius: 6
    color: rowHover.hovered ? Theme.palette.backgroundTertiary : Theme.palette.backgroundSecondary
    Behavior on color { ColorAnimation { duration: 120 } }
    HoverHandler { id: rowHover; cursorShape: Qt.PointingHandCursor }
    // Under the buttons: they take their own clicks, so only the rest of the row opens it.
    TapHandler { onTapped: root.opened() }

    RowLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Theme.spacing.medium
        anchors.rightMargin: Theme.spacing.medium
        spacing: Theme.spacing.medium

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                LogosText {
                    id: nameText
                    objectName: "lezAccountName"
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.maximumWidth: Math.ceil(implicitWidth)
                    text: root.name || ("Account " + Format.shortenHead(root.address))
                    textFormat: Text.PlainText
                    font.bold: true
                    elide: Text.ElideRight
                    HoverHandler { id: nameHover }
                    LogosToolTip { visible: nameText.truncated && nameHover.hovered; text: nameText.text }
                }
                // Only an unnamed account: the core adds labels and can't rename or remove one,
                // so a second save would append a name rather than change it.
                LogosIconButton {
                    objectName: "lezEditNameButton"
                    visible: !root.name
                    flat: true; size: 24; iconSize: 13
                    iconSource: Qt.resolvedUrl("../icons/edit.svg")
                    iconColor: hovered ? Theme.palette.text : Theme.palette.textTertiary
                    onClicked: root.labelRequested(root.accountId, root.isPublic)
                    LogosToolTip { text: qsTr("Name this account"); visible: parent.hovered; delay: 400 }
                }
                Item { Layout.fillWidth: true }
                LogosText {
                    objectName: "lezAccountBalance"
                    text: root.balance.length > 0 ? Units.format(root.balance) : "—"
                    textFormat: Text.PlainText
                    color: Theme.palette.primary
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                LogosText {
                    text: qsTr("Address")
                    color: Theme.palette.textSecondary
                    font.pixelSize: Theme.typography.secondaryText
                }
                LogosText {
                    objectName: "lezAccountAddress"
                    text: Format.shortenMiddle(root.address)
                    textFormat: Text.PlainText
                    font.family: Theme.typography.mono
                    font.pixelSize: Theme.typography.secondaryText
                }
                LogosCopyButton {
                    objectName: "lezAccountCopy"
                    visible: root.address.length > 0
                    value: root.address
                    Accessible.name: qsTr("Copy address")
                    LogosToolTip { text: qsTr("Copy address"); visible: parent.hovered; delay: 400 }
                }
                Item { Layout.fillWidth: true }
                // Public accounts only: private ones aren't on chain in the clear.
                LogosIconButton {
                    objectName: "lezViewAccountInExplorerButton"
                    visible: root.isPublic
                    flat: true; size: 24; iconSize: 16
                    iconSource: Qt.resolvedUrl("../icons/explorer.svg")
                    iconColor: hovered ? Theme.palette.text : Theme.palette.textTertiary
                    onClicked: root.viewInExplorerRequested(root.address)
                    LogosToolTip { text: qsTr("View in explorer"); visible: parent.hovered; delay: 400 }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: !root.isPublic && !!root.keys.nullifier_public_key
                spacing: 6
                LogosText {
                    text: qsTr("Keys")
                    color: Theme.palette.textSecondary
                    font.pixelSize: Theme.typography.secondaryText
                }
                LogosText {
                    objectName: "lezAccountKeys"
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.maximumWidth: Math.ceil(implicitWidth)
                    elide: Text.ElideRight
                    text: "Npk " + Format.shortenMiddle(root.keys.nullifier_public_key || "")
                          + " · Vpk " + Format.shortenMiddle(root.keys.viewing_public_key || "")
                    textFormat: Text.PlainText
                    font.family: Theme.typography.mono
                    font.pixelSize: Theme.typography.secondaryText
                }
                LogosCopyButton {
                    objectName: "lezAccountKeysCopy"
                    value: root.keysJson
                    Accessible.name: qsTr("Copy keys")
                    LogosToolTip { text: qsTr("Copy keys: what someone needs to send to this account privately"); visible: parent.hovered; delay: 400 }
                }
                Item { Layout.fillWidth: true }
            }
        }

    }
}
