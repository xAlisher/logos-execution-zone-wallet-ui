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
// its name, balance and Send, centred; how to receive to it, always shown; then its activity.
// It follows the row on screen (`row`), so a new balance or name shows here as in the list.
Item {
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

    // A titled block on a rounded panel, as the Receive and Address parts are.
    component Panel: Rectangle {
        id: panel
        property string title: ""
        default property alias content: panelColumn.data
        Layout.fillWidth: true
        radius: 6
        color: Theme.palette.backgroundSecondary
        implicitHeight: panelColumn.implicitHeight + 2 * Theme.spacing.medium
        ColumnLayout {
            id: panelColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.spacing.medium
            spacing: Theme.spacing.small
            LogosText {
                Layout.fillWidth: true
                text: panel.title
                font.weight: Theme.typography.weightBold
            }
        }
    }

    // Small print under a block.
    component Note: LogosText {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        color: Theme.palette.textSecondary
        font.pixelSize: Theme.typography.secondaryText
    }

    LogosScrollView {
        id: scroll
        anchors.fill: parent
        contentWidth: availableWidth

        ColumnLayout {
            width: scroll.availableWidth
            spacing: Theme.spacing.medium

            // ‹ Accounts, the way back.
            RowLayout {
                objectName: "lezAccountBack"
                spacing: 2
                readonly property color tint: backHover.hovered ? Theme.palette.text : Theme.palette.textSecondary
                LogosIcon {
                    source: LogosIcons.arrowLeft
                    width: 16; height: 16
                    color: parent.tint
                }
                LogosText {
                    text: qsTr("Accounts")
                    color: parent.tint
                    font.pixelSize: Theme.typography.secondaryText
                }
                HoverHandler { id: backHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.backRequested() }
            }

            // Name, kind, balance and Send, centred on the column.
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: scroll.availableWidth
                spacing: 4
                RowLayout {
                    // A layout inside a layout fills by default; this one is its content's width.
                    Layout.fillWidth: false
                    Layout.alignment: Qt.AlignHCenter
                    Layout.maximumWidth: scroll.availableWidth
                    spacing: 8
                    LogosText {
                        objectName: "lezAccountPageName"
                        // Its own width, so the row stays as wide as its content and centres;
                        // a long name elides before it pushes the pencil and the tag out.
                        Layout.maximumWidth: Math.max(0, scroll.availableWidth - 120)
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
                }
                LogosText {
                    objectName: "lezAccountPageBalance"
                    Layout.alignment: Qt.AlignHCenter
                    text: root.row && root.row.balance.length > 0 ? Units.format(root.row.balance) : "—"
                    textFormat: Text.PlainText
                    color: Theme.palette.primary
                    font.pixelSize: Theme.typography.titleText
                }
                LogosButton {
                    objectName: "lezAccountPageSend"
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Theme.spacing.small
                    Layout.preferredWidth: 240
                    variant: LogosButton.Variant.Primary
                    text: qsTr("Send")
                    onClicked: root.sendRequested(root.row.accountId, root.isPublic)
                }
            }

            // Receive, public: the address is what gets paid, so it is the code, in full and to copy.
            Panel {
                objectName: "lezAccountPageReceivePublic"
                visible: root.isPublic
                title: qsTr("Receive public transfer")

                QrCode {
                    objectName: "lezAccountPageQr"
                    Layout.alignment: Qt.AlignHCenter
                    visible: root.isPublic
                    targetSize: 200
                    text: root.address
                }
                Note {
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("Share this address to receive public transfers. To bring tokens in "
                               + "from the Blockchain app, deposit to it there.")
                }
                LogosText {
                    Layout.topMargin: Theme.spacing.small
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
                    LogosCopyButton {
                        objectName: "lezAccountPageCopyAddress"
                        value: root.address
                        LogosToolTip { text: qsTr("Copy address"); visible: parent.hovered; delay: 400 }
                    }
                    LogosIconButton {
                        flat: true; size: 24; iconSize: 16
                        iconSource: Qt.resolvedUrl("../icons/explorer.svg")
                        iconColor: hovered ? Theme.palette.text : Theme.palette.textTertiary
                        onClicked: root.viewInExplorerRequested(root.address)
                        LogosToolTip { text: qsTr("View in explorer"); visible: parent.hovered; delay: 400 }
                    }
                }
            }

            // Receive, private: a private transfer is made out to the keys. No QR: the keys run to
            // about 2,500 characters (mostly the viewing key), past what a QR code holds at
            // medium error correction, and no camera reads a code that dense off a screen.
            Panel {
                objectName: "lezAccountPageReceivePrivate"
                visible: !root.isPublic
                title: qsTr("Receive private transfer")

                Note {
                    text: qsTr("Share these keys to receive privately. A private transfer is made "
                               + "out to them.")
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    LogosText {
                        objectName: "lezAccountPageKeys"
                        Layout.minimumWidth: 0
                        Layout.maximumWidth: Math.ceil(implicitWidth)
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: "Npk " + Format.shortenMiddle(root.keys.nullifier_public_key || "")
                              + " · Vpk " + Format.shortenMiddle(root.keys.viewing_public_key || "")
                        textFormat: Text.PlainText
                        font.family: Theme.typography.mono
                        font.pixelSize: Theme.typography.secondaryText
                    }
                    LogosCopyButton {
                        objectName: "lezAccountPageCopyKeys"
                        value: root.keysJson
                        LogosToolTip { text: qsTr("Copy keys"); visible: parent.hovered; delay: 400 }
                    }
                    Item { Layout.fillWidth: true }
                }
            }

            // A private account's address: the wallet's own name for it. It picks the account to
            // spend from and the one to pay between your accounts, but nobody can pay to it.
            Panel {
                objectName: "lezAccountPagePrivateAddress"
                visible: !root.isPublic
                title: qsTr("Address")

                LogosSelectableText {
                    Layout.fillWidth: true
                    text: root.address
                    wrapMode: Text.WrapAnywhere
                    font.family: Theme.typography.mono
                    font.pixelSize: Theme.typography.secondaryText
                }
                Note {
                    text: qsTr("For your own reference and for transfers between your accounts. "
                               + "Nobody can send to it, so there is no point sharing it: to be paid "
                               + "privately, share the keys above.")
                }
            }

            LogosText {
                Layout.topMargin: Theme.spacing.small
                text: qsTr("Activity")
                font.pixelSize: Theme.typography.subtitleText
                font.weight: Theme.typography.weightBold
            }

            Note {
                visible: !root.isPublic
                text: qsTr("A private account's activity isn't on chain in the clear, and the "
                           + "wallet keeps no history of it yet.")
            }

            ActivityView {
                objectName: "lezAccountPageActivity"
                Layout.fillWidth: true
                Layout.preferredHeight: 320
                visible: root.isPublic
                walletBackend: root.walletBackend
                fixedAccount: root.isPublic ? root.address : ""
                limit: 10
                onOpenTxRequested: (h) => root.openTxRequested(h)
            }
        }
    }
}
