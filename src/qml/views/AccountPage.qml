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

    // A public account's public key (hex). In v0.4 the first transfer to a new public account
    // has to carry it: the address is a hash of the key, so the address alone can't be paid
    // until the account exists.
    property string publicKeyHex: ""
    function loadPublicKey() {
        root.publicKeyHex = ""
        if (!root.walletBackend || !root.row || !root.row.isPublic) return
        logos.watch(root.walletBackend.getPublicAccountKey(root.row.accountId),
            function (key) { root.publicKeyHex = /^[0-9a-fA-F]{64}$/.test(key || "") ? key.toLowerCase() : "" },
            function (err) { root.publicKeyHex = "" })
    }
    onRowChanged: loadPublicKey()
    readonly property string keysJson: row ? row.keysJson : ""
    readonly property var keys: row ? row.keys : ({})

    // A titled block on a rounded panel, as the Receive and Address parts are.
    component Panel: Rectangle {
        id: panel
        property string title: ""
        // What the block is for, in small print right under its title.
        property string description: ""
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
            LogosText {
                Layout.fillWidth: true
                visible: text.length > 0
                text: panel.description
                wrapMode: Text.WordWrap
                color: Theme.palette.textSecondary
                font.pixelSize: Theme.typography.secondaryText
            }
        }
    }


    LogosScrollView {
        id: scroll
        anchors.fill: parent
        // The scroll view spans the tab, so its bar sits at the window's edge; the content is
        // the 560 column, centred, as PageColumn lays out the other tabs.
        contentWidth: availableWidth
        contentHeight: column.implicitHeight + 2 * Theme.spacing.large

        ColumnLayout {
            id: column
            x: Math.round((scroll.availableWidth - width) / 2)
            y: Theme.spacing.large
            width: Math.min(560, scroll.availableWidth - 2 * Theme.spacing.xlarge)
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
                Layout.preferredWidth: column.width
                spacing: 4
                RowLayout {
                    // A layout inside a layout fills by default; this one is its content's width.
                    Layout.fillWidth: false
                    Layout.alignment: Qt.AlignHCenter
                    Layout.maximumWidth: column.width
                    spacing: 8
                    LogosText {
                        objectName: "lezAccountPageName"
                        // Its own width, so the row stays as wide as its content and centres;
                        // a long name elides before it pushes the tag out.
                        Layout.maximumWidth: Math.max(0, column.width - 120)
                        text: root.row ? (root.row.name || ("Account " + Format.shortenHead(root.address))) : ""
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        font.pixelSize: Theme.typography.titleText
                        font.weight: Theme.typography.weightBold
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
                // Send first and strongest; then the account's own secondary actions.
                RowLayout {
                    Layout.fillWidth: false
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Theme.spacing.small
                    Layout.bottomMargin: Theme.spacing.large
                    spacing: Theme.spacing.small
                    LogosButton {
                        objectName: "lezAccountPageSend"
                        Layout.preferredWidth: 200
                        variant: LogosButton.Variant.Primary
                        text: qsTr("Send")
                        onClicked: root.sendRequested(root.row.accountId, root.isPublic)
                    }
                    // The core adds names and can't change or remove one, and an account's name is
                    // all of its names joined: so a named account can't be renamed from here yet.
                    // Wrapped: a disabled button gets no hover, and its tooltip is the reason.
                    Item {
                        implicitWidth: renameButton.implicitWidth
                        implicitHeight: renameButton.implicitHeight
                        LogosButton {
                            id: renameButton
                            objectName: "lezAccountPageRename"
                            readonly property bool named: !!root.row && root.row.name.length > 0
                            anchors.fill: parent
                            enabled: !named
                            text: named ? qsTr("Rename") : qsTr("Name")
                            onClicked: root.labelRequested(root.row.accountId, root.isPublic)
                        }
                        HoverHandler { id: renameHover }
                        LogosToolTip {
                            visible: renameButton.named && renameHover.hovered
                            text: qsTr("The wallet can't change a name once it is set yet.")
                        }
                    }
                    // Public only: a private account isn't on chain in the clear.
                    LogosButton {
                        objectName: "lezAccountPageExplorer"
                        visible: root.isPublic
                        text: qsTr("View in explorer")
                        onClicked: root.viewInExplorerRequested(root.address)
                    }
                }
            }

            // Receive, public: the address is what gets paid, so it is the code, in full and to copy.
            Panel {
                objectName: "lezAccountPageReceivePublic"
                visible: root.isPublic
                title: qsTr("Receive public transfer")
                description: qsTr("Share this address to receive public transfers. To bring tokens "
                                  + "in from the Blockchain app, deposit to it there.")

                QrCode {
                    objectName: "lezAccountPageQr"
                    Layout.alignment: Qt.AlignHCenter
                    visible: root.isPublic
                    targetSize: 280
                    text: root.address
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
                        // As wide as the address, so copy sits right after it; wraps when narrower.
                        Layout.fillWidth: true
                        Layout.maximumWidth: Math.ceil(implicitWidth)
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
                    Item { Layout.fillWidth: true }
                }
                LogosText {
                    Layout.topMargin: Theme.spacing.small
                    text: qsTr("Public key")
                    color: Theme.palette.textSecondary
                    font.pixelSize: Theme.typography.secondaryText
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    LogosSelectableText {
                        objectName: "lezAccountPagePublicKey"
                        Layout.fillWidth: true
                        Layout.maximumWidth: Math.ceil(implicitWidth)
                        text: root.publicKeyHex.length > 0 ? root.publicKeyHex : "…"
                        wrapMode: Text.WrapAnywhere
                        font.family: Theme.typography.mono
                        font.pixelSize: Theme.typography.secondaryText
                    }
                    LogosCopyButton {
                        objectName: "lezAccountPageCopyPublicKey"
                        visible: root.publicKeyHex.length > 0
                        value: root.publicKeyHex
                        LogosToolTip { text: qsTr("Copy public key"); visible: parent.hovered; delay: 400 }
                    }
                    Item { Layout.fillWidth: true }
                }
                LogosText {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: qsTr("Only for the very first transfer to this account: until it has "
                               + "received once, a sender needs the public key. After that the "
                               + "address is enough.")
                    color: Theme.palette.textTertiary
                    font.pixelSize: Theme.typography.secondaryText
                }
            }

            // Receive, private: a private transfer is made out to the keys. No QR: the keys run to
            // about 2,500 characters (mostly the viewing key), past what a QR code holds at
            // medium error correction, and no camera reads a code that dense off a screen.
            Panel {
                objectName: "lezAccountPageReceivePrivate"
                visible: !root.isPublic
                title: qsTr("Receive private transfer")
                description: qsTr("Share these keys to receive privately. A private transfer is "
                                  + "made out to them.")
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
                description: qsTr("For your own reference and for transfers between your accounts. "
                                  + "Nobody can send to it, so there is no point sharing it: to be "
                                  + "paid privately, share the keys above.")

                LogosSelectableText {
                    Layout.fillWidth: true
                    text: root.address
                    wrapMode: Text.WrapAnywhere
                    font.family: Theme.typography.mono
                    font.pixelSize: Theme.typography.secondaryText
                }
            }

            Panel {
                objectName: "lezAccountPageActivityPanel"
                title: qsTr("Activity")
                description: root.isPublic ? ""
                             : qsTr("A private account's activity isn't on chain in the clear, and "
                                    + "the wallet keeps no history of it yet.")

                ActivityView {
                    objectName: "lezAccountPageActivity"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 280
                    visible: root.isPublic
                    walletBackend: root.walletBackend
                    fixedAccount: root.isPublic ? root.address : ""
                    limit: 10
                    onOpenTxRequested: (h) => root.openTxRequested(h)
                }
            }
        }
    }
}
