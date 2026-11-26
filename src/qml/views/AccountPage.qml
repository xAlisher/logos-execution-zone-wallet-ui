import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Logos.Theme
import Logos.Controls
import Logos.Icons

import "../controls"
import "../Format.js" as Format
import "../Units.js" as Units

// One account, opened from its row on the Accounts tab, as the Ethereum wallet opens a token:
// its name and balance, Send and Receive, then its activity. It follows the row on screen
// (`row`), so a new balance or a new name shows here as it does in the list.
ColumnLayout {
    id: root

    // The account's AccountRow on the Accounts tab; null once it is gone.
    property var row: null
    property var walletBackend: null

    signal backRequested()
    signal sendRequested(string accountId, bool isPublic)
    signal labelRequested(string accountId, bool isPublic)
    signal viewInExplorerRequested(string accountIdBase58)
    signal openTxRequested(string txHash)

    readonly property bool isPublic: row ? row.isPublic : true
    readonly property string address: row ? row.address : ""
    readonly property string keysJson: row ? row.keysJson : ""
    readonly property var keys: row ? row.keys : ({})
    property bool receiveShown: false

    spacing: Theme.spacing.medium

    // ‹ Accounts, the way back, as a detail screen in the other wallets has one.
    RowLayout {
        objectName: "lezAccountBack"
        spacing: 2
        LogosIcon {
            source: LogosIcons.arrowLeft
            width: 16; height: 16
            color: Theme.palette.textSecondary
        }
        LogosText {
            text: qsTr("Accounts")
            color: Theme.palette.textSecondary
            font.pixelSize: Theme.typography.secondaryText
        }
        HoverHandler { cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: root.backRequested() }
    }

    // Name, kind and balance.
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            LogosText {
                objectName: "lezAccountPageName"
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.maximumWidth: Math.ceil(implicitWidth)
                text: root.row ? (root.row.name || ("Account " + Format.shortenHead(root.address))) : ""
                textFormat: Text.PlainText
                elide: Text.ElideRight
                font.pixelSize: Theme.typography.titleText
                font.weight: Theme.typography.weightBold
            }
            LogosIconButton {
                visible: !!root.row && !root.row.name
                flat: true; size: 24; iconSize: 16
                iconSource: Qt.resolvedUrl("../icons/edit.svg")
                iconColor: hovered ? Theme.palette.text : Theme.palette.textTertiary
                onClicked: root.labelRequested(root.row.accountId, root.isPublic)
                LogosToolTip { text: qsTr("Name this account"); visible: parent.hovered; delay: 400 }
            }
            LogosText {
                text: root.isPublic ? qsTr("Public") : qsTr("Private")
                color: Theme.palette.textSecondary
                font.weight: Theme.typography.weightBold
                font.pixelSize: Theme.typography.secondaryText
            }
            Item { Layout.fillWidth: true }
        }
        LogosText {
            objectName: "lezAccountPageBalance"
            text: root.row && root.row.balance.length > 0 ? Units.format(root.row.balance) : "—"
            textFormat: Text.PlainText
            color: Theme.palette.primary
            font.pixelSize: Theme.typography.titleText
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacing.small
        LogosButton {
            objectName: "lezAccountPageSend"
            Layout.fillWidth: true
            variant: LogosButton.Variant.Primary
            text: qsTr("Send")
            onClicked: root.sendRequested(root.row.accountId, root.isPublic)
        }
        LogosButton {
            objectName: "lezAccountPageReceive"
            Layout.fillWidth: true
            text: root.receiveShown ? qsTr("Hide") : qsTr("Receive")
            onClicked: root.receiveShown = !root.receiveShown
        }
    }

    // Receive. A public account receives at its address. A private one receives at its keys:
    // a private transfer is made out to them, so the address alone can't be paid by anyone else.
    Rectangle {
        objectName: "lezAccountPageReceivePanel"
        Layout.fillWidth: true
        visible: root.receiveShown
        radius: 6
        color: Theme.palette.backgroundSecondary
        implicitHeight: receiveColumn.implicitHeight + 2 * Theme.spacing.medium

        ColumnLayout {
            id: receiveColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.spacing.medium
            spacing: Theme.spacing.small

            // Public only. A private account's keys run to about 2,500 characters (the viewing
            // key is most of it): past what a QR code holds at medium error correction, and a
            // 177-module code at the limit that no camera reads off a screen. Copy is the way.
            QrCode {
                objectName: "lezAccountPageQr"
                Layout.alignment: Qt.AlignHCenter
                visible: root.receiveShown && root.isPublic
                targetSize: 200
                text: root.address
            }
            LogosText {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                text: root.isPublic
                      ? qsTr("Share this address to receive public transfers. To bring tokens in "
                             + "from the Blockchain app, deposit to it there.")
                      : qsTr("Share these keys to receive privately. A private transfer is made out "
                             + "to the keys, so the address alone can't be paid.")
                color: Theme.palette.textSecondary
                font.pixelSize: Theme.typography.secondaryText
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6
                LogosText {
                    objectName: "lezAccountPageReceiveValue"
                    text: root.isPublic
                          ? Format.shortenMiddle(root.address)
                          : "Npk " + Format.shortenMiddle(root.keys.nullifier_public_key || "")
                            + " · Vpk " + Format.shortenMiddle(root.keys.viewing_public_key || "")
                    textFormat: Text.PlainText
                    font.family: Theme.typography.mono
                    font.pixelSize: Theme.typography.secondaryText
                }
                LogosCopyButton {
                    objectName: "lezAccountPageReceiveCopy"
                    value: root.isPublic ? root.address : root.keysJson
                    LogosToolTip { text: root.isPublic ? qsTr("Copy address") : qsTr("Copy keys"); visible: parent.hovered; delay: 400 }
                }
            }
        }
    }

    // Details: the address in full, checked character by character here rather than in the
    // shortened form of the list.
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        LogosText {
            text: qsTr("Address")
            color: Theme.palette.textSecondary
            font.pixelSize: Theme.typography.secondaryText
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            LogosSelectableText {
                objectName: "lezAccountPageAddress"
                Layout.fillWidth: true
                text: root.address
                wrapMode: Text.WrapAnywhere
                font.family: Theme.typography.mono
                font.pixelSize: Theme.typography.secondaryText
            }
            // Only a public address is something to hand out; see Receive.
            LogosCopyButton {
                visible: root.isPublic
                value: root.address
                LogosToolTip { text: qsTr("Copy address"); visible: parent.hovered; delay: 400 }
            }
            LogosIconButton {
                visible: root.isPublic
                flat: true; size: 24; iconSize: 16
                iconSource: Qt.resolvedUrl("../icons/explorer.svg")
                iconColor: hovered ? Theme.palette.text : Theme.palette.textTertiary
                onClicked: root.viewInExplorerRequested(root.address)
                LogosToolTip { text: qsTr("View in explorer"); visible: parent.hovered; delay: 400 }
            }
        }
    }

    LogosText {
        Layout.topMargin: Theme.spacing.small
        text: qsTr("Activity")
        font.pixelSize: Theme.typography.subtitleText
        font.weight: Theme.typography.weightBold
    }

    LogosText {
        visible: !root.isPublic
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: qsTr("A private account's activity isn't on chain in the clear, and the wallet "
                   + "keeps no history of it yet.")
        color: Theme.palette.textSecondary
        font.pixelSize: Theme.typography.secondaryText
    }

    ActivityView {
        objectName: "lezAccountPageActivity"
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.isPublic
        walletBackend: root.walletBackend
        fixedAccount: root.isPublic ? root.address : ""
        limit: 10
        onOpenTxRequested: (h) => root.openTxRequested(h)
    }

    Item { Layout.fillHeight: !root.isPublic }
}
