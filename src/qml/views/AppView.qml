import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Logos.Theme
import Logos.Controls

// The unlocked LEZ app's wallet pages, one per tab: Balance, Send, Bridge, Activity, Settings
// (Explorer is the frame's own). Each is a 560 column, as in the other wallet apps. Same
// inputs and outputs as the old two-pane DashboardView, so the parent's wiring is unchanged.
Item {
    id: root

    // "balance", "send", "bridge", "activity" or "settings".
    property string page: "balance"

    // --- inputs ---
    property var walletBackend: null
    property var accountModel: null
    property var publicAccountModel: null
    property var privateAccountModel: null
    property string transferResult: ""
    property string transferTxHash: ""
    property bool transferResultIsError: false
    property bool transferPending: false
    property int lastSyncedBlock: 0
    property int currentBlockHeight: 0
    property string sequencerAddr: ""
    property string syncProblem: ""
    property var networkPresets: []
    property string networkName: ""
    property string storagePath: ""

    // --- outputs ---
    signal createPublicAccountRequested()
    signal createPrivateAccountRequested()
    signal fetchBalancesRequested()
    signal transferPublicRequested(string fromAccountId, string toAddress, string amount)
    signal transferPrivateRequested(string fromAccountId, string toKeysJsonOrAddress, string amount)
    signal transferPrivateOwnedRequested(string fromAccountId, string toAccountId, string amount)
    signal transferShieldedRequested(string fromAccountId, string toKeysJsonOrAddress, string amount)
    signal transferShieldedOwnedRequested(string fromAccountId, string toAccountId, string amount)
    signal transferDeshieldedRequested(string fromAccountId, string toAccountId, string amount)
    signal bridgeWithdrawRequested(string fromAccountId, string bedrockAccountPkHex, string amount)
    signal labelRequested(string accountId, bool isPublic)
    signal viewTxInExplorerRequested(string txHash)
    signal viewAccountInExplorerRequested(string accountIdBase58)
    // A tab the page wants shown, e.g. Send from an account's page.
    signal tabRequested(string key)

    // The account whose page is open on the Accounts tab; "" shows the list. Leaving the tab
    // closes it, as a detail screen closes when another tab is chosen in the other wallets.
    property string openAccountId: ""
    onPageChanged: openAccountId = ""

    StackLayout {
        anchors.fill: parent
        currentIndex: ["balance", "send", "bridge", "activity", "settings"].indexOf(root.page)

        // ---- Accounts ----
        // Not a PageColumn: the list and the account page scroll, and their bars belong at the
        // tab's edge, so each centres its own 560 column inside a full-width scroll view.
        Item {
            objectName: "lezPageBalance"
            AccountsPanel {
                id: accountsPanel
                anchors.fill: parent
                visible: root.openAccountId.length === 0
                publicAccountModel: root.publicAccountModel
                privateAccountModel: root.privateAccountModel
                lastSyncedBlock: root.lastSyncedBlock
                currentBlockHeight: root.currentBlockHeight
                syncProblem: root.syncProblem
                onCreatePublicAccountRequested: root.createPublicAccountRequested()
                onCreatePrivateAccountRequested: root.createPrivateAccountRequested()
                onLabelRequested: (accountId, isPublic) => root.labelRequested(accountId, isPublic)
                onViewAccountInExplorerRequested: (id) => root.viewAccountInExplorerRequested(id)
                onAccountOpened: (id) => root.openAccountId = id
            }
            AccountPage {
                objectName: "lezAccountPage"
                anchors.fill: parent
                visible: root.openAccountId.length > 0
                row: root.openAccountId.length > 0 ? accountsPanel.rowFor(root.openAccountId) : null
                walletBackend: root.walletBackend
                onBackRequested: root.openAccountId = ""
                onSendRequested: (id, isPublic) => {
                    root.tabRequested("send")
                    sendPanel.preselect(id, isPublic)
                }
                onLabelRequested: (accountId, isPublic) => root.labelRequested(accountId, isPublic)
                onViewInExplorerRequested: (id) => root.viewAccountInExplorerRequested(id)
                onOpenTxRequested: (h) => root.viewTxInExplorerRequested(h)
            }
        }

        // ---- Send ----
        PageColumn {
            objectName: "lezPageSend"
            TransferTypesPanel {
                id: sendPanel
                Layout.fillWidth: true
                Layout.fillHeight: true
                publicAccountModel: root.publicAccountModel
                privateAccountModel: root.privateAccountModel
                transferPending: root.transferPending
                onTransferPublicRequested: (fromId, toAddress, amount) => root.transferPublicRequested(fromId, toAddress, amount)
                onTransferPrivateRequested: (fromId, toKeys, amount) => root.transferPrivateRequested(fromId, toKeys, amount)
                onTransferPrivateOwnedRequested: (fromId, toId, amount) => root.transferPrivateOwnedRequested(fromId, toId, amount)
                onTransferShieldedRequested: (fromId, toKeys, amount) => root.transferShieldedRequested(fromId, toKeys, amount)
                onTransferShieldedOwnedRequested: (fromId, toId, amount) => root.transferShieldedOwnedRequested(fromId, toId, amount)
                onTransferDeshieldedRequested: (fromId, toId, amount) => root.transferDeshieldedRequested(fromId, toId, amount)
            }
            TransferResult {
                Layout.fillWidth: true
                transferResult: root.transferResult
                transferTxHash: root.transferTxHash
                transferResultIsError: root.transferResultIsError
                transferPending: root.transferPending
                onViewInExplorerRequested: (h) => root.viewTxInExplorerRequested(h)
            }
        }

        // ---- Bridge ----
        PageColumn {
            objectName: "lezPageBridge"
            LogosFrame {
                objectName: "lezBridgeDepositNote"
                Layout.fillWidth: true
                contentItem: LogosText {
                    wrapMode: Text.WordWrap
                    text: qsTr("To bring tokens in, deposit from the Blockchain app (Channel "
                               + "Deposit, with your public account as the recipient). They arrive "
                               + "once the deposit is final. Below: withdraw to a Bedrock account.")
                    color: Theme.palette.textSecondary
                    font.pixelSize: Theme.typography.secondaryText
                }
            }
            BridgePanel {
                Layout.fillWidth: true
                Layout.fillHeight: true
                publicAccountModel: root.publicAccountModel
                transferPending: root.transferPending
                onBridgeWithdrawRequested: (fromId, pk, amount) => root.bridgeWithdrawRequested(fromId, pk, amount)
            }
            TransferResult {
                Layout.fillWidth: true
                transferResult: root.transferResult
                transferTxHash: root.transferTxHash
                transferResultIsError: root.transferResultIsError
                transferPending: root.transferPending
                onViewInExplorerRequested: (h) => root.viewTxInExplorerRequested(h)
            }
        }

        // ---- Activity ----
        PageColumn {
            objectName: "lezPageActivity"
            ActivityView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                walletBackend: root.walletBackend
                publicAccountModel: root.publicAccountModel
                onOpenTxRequested: (h) => root.viewTxInExplorerRequested(h)
            }
        }

        // ---- Settings ----
        PageColumn {
            objectName: "lezPageSettings"
            SettingsView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                walletBackend: root.walletBackend
                networkName: root.networkName
                sequencerAddr: root.sequencerAddr
                storagePath: root.storagePath
            }
        }
    }
}
