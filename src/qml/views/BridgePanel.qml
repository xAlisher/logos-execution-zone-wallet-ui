import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Logos.Theme
import Logos.Controls

import "../controls"

// Bridge: the two directions between LEZ and the Logos Blockchain (L1), picked like Send's
// transfer types. LEZ → L1 is a withdrawal made here; L1 → LEZ is a deposit made in the
// Blockchain app, so that side gives the steps and the values to carry over.
ColumnLayout {
    id: root

    spacing: Theme.spacing.medium

    // --- Public API: data in ---
    property var publicAccountModel: null
    property var walletBackend: null
    property string channelId: ""
    property string networkName: ""
    property bool transferPending: false
    property int labelPixelSize: 14

    // --- Public API: signals out ---
    signal bridgeWithdrawRequested(string fromAccountId, string bedrockAccountPkHex, string amount)

    readonly property var descriptions: [
        qsTr("Bridge from a public account to a Logos Blockchain (L1) account."),
        qsTr("Bridge from the Logos Blockchain (L1) into a public account. It is made "
             + "in the Blockchain app; here is what it needs.")
    ]

    PillTabBar {
        id: directionBar
        objectName: "lezBridgeDirection"
        Layout.fillWidth: true
        spacing: Theme.spacing.small
        currentIndex: 0
        PillTabButton { text: qsTr("LEZ → L1") }
        PillTabButton { text: qsTr("L1 → LEZ") }
    }

    LogosText {
        objectName: "lezBridgeDescription"
        Layout.fillWidth: true
        Layout.bottomMargin: Theme.spacing.medium
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: root.descriptions[Math.max(0, directionBar.currentIndex)]
        color: Theme.palette.textSecondary
        font.pixelSize: Theme.typography.secondaryText
    }

    // One direction at a time, each as tall as its own content: the page scrolls, not this.
    WithdrawPanel {
        Layout.fillWidth: true
        visible: directionBar.currentIndex === 0
        publicAccountModel: root.publicAccountModel
        transferPending: root.transferPending
        labelPixelSize: root.labelPixelSize
        onBridgeWithdrawRequested: (fromId, pk, amount) => root.bridgeWithdrawRequested(fromId, pk, amount)
    }

    DepositPanel {
        objectName: "lezBridgeDeposit"
        Layout.fillWidth: true
        visible: directionBar.currentIndex === 1
        publicAccountModel: root.publicAccountModel
        walletBackend: root.walletBackend
        channelId: root.channelId
        networkName: root.networkName
        labelPixelSize: root.labelPixelSize
    }
}
