import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Logos.Theme
import Logos.Controls

import "../controls"
import "../explorer/components"
import "../Base58.js" as Base58

// Activity, partial on purpose: the wallet keeps no transaction history, but the Explorer
// can list a public account's transactions, so that is what shows. Private accounts aren't
// on chain in the clear, and nothing lists their history yet: the note says so.
ColumnLayout {
    id: root

    property var publicAccountModel: null
    property var walletBackend: null

    signal openTxRequested(string txHash)

    property var txs: []
    property bool loading: false
    property bool loaded: false
    readonly property string accountBase58: accountPicker.currentValue
                                            ? Base58.encode(accountPicker.currentValue) : ""

    function load() {
        if (!root.walletBackend || root.accountBase58.length === 0) {
            root.txs = []
            root.loaded = false
            return
        }
        root.loading = true
        logos.watch(root.walletBackend.explorerGetTransactionsByAccount(root.accountBase58, 0, 20),
            function (result) { root.txs = result || []; root.loading = false; root.loaded = true },
            function (err) { root.txs = []; root.loading = false; root.loaded = true })
    }
    onAccountBase58Changed: load()
    onVisibleChanged: if (visible) load()

    spacing: Theme.spacing.medium

    LogosText {
        text: qsTr("Activity")
        color: Theme.palette.text
        font.pixelSize: Theme.typography.titleText
        font.weight: Theme.typography.weightBold
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacing.small
        AccountComboBox {
            id: accountPicker
            objectName: "lezActivityAccountPicker"
            Layout.fillWidth: true
            model: root.publicAccountModel
            // The first public account, so the tab shows something without a pick.
            onCountChanged: if (count > 0 && currentIndex < 0) currentIndex = 0
            Component.onCompleted: if (count > 0 && currentIndex < 0) currentIndex = 0
        }
        LogosButton {
            objectName: "lezActivityRefreshButton"
            compact: true
            text: qsTr("Refresh")
            enabled: !root.loading
            onClicked: root.load()
        }
    }

    LogosText {
        objectName: "lezActivityNote"
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: qsTr("Transactions of your public accounts, as the Explorer sees them. Private "
                   + "accounts' activity isn't shown yet.")
        color: Theme.palette.textTertiary
        font.pixelSize: Theme.typography.secondaryText
    }

    LogosText {
        objectName: "lezActivityEmpty"
        Layout.fillWidth: true
        Layout.topMargin: Theme.spacing.large
        visible: !root.loading && root.txs.length === 0
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: root.accountBase58.length === 0
              ? qsTr("Create a public account to see its activity.")
              : root.loaded ? qsTr("No transactions found for this account. The Explorer lists "
                                   + "only what its sequencer has indexed.")
                            : ""
        color: Theme.palette.textSecondary
        font.pixelSize: Theme.typography.secondaryText
    }

    LogosSpinner {
        Layout.alignment: Qt.AlignHCenter
        visible: root.loading
        running: root.loading
    }

    ListView {
        objectName: "lezActivityList"
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: Theme.spacing.small
        model: root.txs
        delegate: ExTxRow {
            width: ListView.view.width
            tx: modelData
            onClicked: root.openTxRequested(modelData.hash || "")
        }
    }
}
