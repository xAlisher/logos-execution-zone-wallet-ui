import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Logos.Theme
import Logos.Controls
import "views"
import "popups"
import "explorer"

Rectangle {
    id: root

    readonly property var backend: logos.module("lez_wallet_ui")
    readonly property var accountModel: logos.model("lez_wallet_ui", "accountModel")
    readonly property var publicAccountModel: logos.model("lez_wallet_ui", "filteredAccountModel")
    readonly property var privateAccountModel: logos.model("lez_wallet_ui", "privateAccountModel")
    property bool ready: false

    Connections {
        target: logos
        function onViewModuleReadyChanged(moduleName, isReady) {
            if (moduleName === "lez_wallet_ui")
                root.ready = isReady && root.backend !== null
        }
    }

    // Map wallet FFI error codes to user-facing strings. Matches lssa/core-ffi FfiOperationError enum.
    QtObject {
        id: ffiErrors
        readonly property var codeToMessage: ({
            0: qsTr("Success"),
            1: qsTr("Invalid argument (null pointer)"),
            2: qsTr("Invalid UTF-8 string"),
            3: qsTr("Invalid argument (malformed or unappiable)"),
            4: qsTr("Sequencer not initialized"),
            5: qsTr("Wallet not initialized"),
            6: qsTr("Configuration error"),
            7: qsTr("Storage or persistence error"),
            8: qsTr("Network or RPC error"),
            9: qsTr("Query failed"),
            10: qsTr("Account not found"),
            11: qsTr("Key not found for account"),
            12: qsTr("Insufficient funds"),
            13: qsTr("Invalid account ID format"),
            14: qsTr("Runtime error"),
            15: qsTr("Password required but not provided"),
            16: qsTr("Block synchronization error"),
            17: qsTr("Serialization error"),
            18: qsTr("Invalid type conversion"),
            19: qsTr("Invalid key value"),
            20: qsTr("Invalid program bytecode"),
            // Fee-admission refusal: distinct from 9, which is the transfer amount check.
            21: qsTr("Insufficient balance to cover the transaction fee"),
            22: qsTr("Not supported"),
            23: qsTr("Response too big"),
            24: qsTr("Message not found"),
            25: qsTr("Wrong password, does not open the wallet storage, or the storage is corrupted"),
            26: qsTr("Would revert"),
            99: qsTr("Internal error")
        })
        function format(errorMessage) {
            if (!errorMessage || typeof errorMessage !== "string")
                return errorMessage || ""
            var match = errorMessage.match(/wallet FFI error (\d+)/)
            if (match) {
                var code = match[1]
                var msg = codeToMessage[code]
                if (msg)
                    return msg
                return qsTr("Wallet error (code %1)").arg(code)
            }
            return errorMessage
        }

        // Parse a transfer result JSON string and write to dashboardView.
        function applyTransferResult(dashboardView, raw) {
            var msg = raw || ""
            var isError = false
            try {
                var obj = JSON.parse(raw)
                if (obj.success) {
                    msg = obj.tx_hash ? qsTr("Success. Tx: %1").arg(obj.tx_hash) : qsTr("Success.")
                } else if (obj.error) {
                    msg = ffiErrors.format(obj.error)
                    isError = true
                }
            } catch (e) {
                if (msg.length > 0) isError = true
            }
            dashboardView.transferResult = msg
            dashboardView.transferResultIsError = isError
            dashboardView.transferTxHash = (obj && obj.tx_hash) ? obj.tx_hash : ""
        }
    }

    QtObject {
        id: d
        readonly property bool isWalletOpen: backend && backend.isWalletOpen
        // Until this is true the backend has not finished deciding whether there
        // is a wallet to open, so "not open" carries no information yet.
        readonly property bool isStartupResolved: backend !== null && backend.isStartupResolved
        // A saved wallet waits for its password before it can open.
        readonly property bool needsPassword: backend !== null && backend.needsPassword

        onIsStartupResolvedChanged: if (root.ready) updateStack(isWalletOpen)
        onNeedsPasswordChanged: if (root.ready) updateStack(isWalletOpen)

        property var currentComponent: null

        function updateStack(walletOpen) {
            const target = !isStartupResolved ? loadingView
                         : (walletOpen ? mainView : onboardingView)
            if (currentComponent === target)
                return
            currentComponent = target
            stackView.replace(target)
        }

        property string noticeMessage: ""
        property int noticeSeverity: LogosNotice.Error
        function showNotice(severity, message) {
            if (!message || message.length === 0) {
                noticeMessage = ""
                bottomNotice.shown = false
                return
            }
            noticeSeverity = severity
            noticeMessage = message
            bottomNotice.show()
        }
    }

    onReadyChanged: if (ready) d.updateStack(d.isWalletOpen)

    Component.onCompleted: {
        root.ready = root.backend !== null
            && logos.isViewModuleReady("lez_wallet_ui")
        if (root.ready) d.updateStack(d.isWalletOpen)
        if (root.backend)
            d.showNotice(LogosNotice.Error, root.backend.notice)
    }

    Connections {
        target: backend
        enabled: backend !== null
        function onNoticeChanged() {
            d.showNotice(LogosNotice.Error, backend.notice)
        }
    }

    color: Theme.palette.background

    SetLabelDialog {
        id: setLabelDialog

        onCheckAvailabilityRequested: (label) => {
            if (!backend) return
            logos.watch(backend.checkLabelAvailable(label),
                function(available) {
                    // The user may have kept typing while this round-trip was in
                    // flight — only apply the result if it still matches the
                    // current text, otherwise it's stale.
                    if (label === setLabelDialog.trimmedText) {
                        setLabelDialog.checkingAvailability = false
                        setLabelDialog.labelAvailable = available
                    }
                },
                function(error) {
                    console.warn("checkLabelAvailable failed:", error)
                    if (label === setLabelDialog.trimmedText) {
                        setLabelDialog.checkingAvailability = false
                        // Fail open — addLabel() itself still validates on submit.
                        setLabelDialog.labelAvailable = true
                    }
                })
        }

        onSaveRequested: (accountId, isPublic, label) => {
            if (!backend) {
                setLabelDialog.reportSaveError(qsTr("Wallet backend unavailable."))
                return
            }
            logos.watch(backend.addLabel(label, accountId, isPublic),
                function(errorMessage) {
                    // The dialog may have been reopened for a different account while
                    // this round-trip was in flight — only apply the result if it's
                    // still about the same account, otherwise it's stale.
                    if (setLabelDialog.accountId !== accountId || setLabelDialog.isPublic !== isPublic)
                        return
                    if (errorMessage)
                        setLabelDialog.reportSaveError(ffiErrors.format(errorMessage))
                    else
                        setLabelDialog.closeOnSaveSuccess()
                },
                function(error) {
                    if (setLabelDialog.accountId !== accountId || setLabelDialog.isPublic !== isPublic)
                        return
                    setLabelDialog.reportSaveError(error)
                })
        }
    }

    LogosToast {
        id: bottomNotice
        objectName: "lezNotice"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spacing.large
        z: 10
        severity: d.noticeSeverity
        message: d.noticeMessage
        duration: 8000
        onDismissed: d.noticeMessage = ""
    }

    // ---- The LEZ app's frame: title, network chip, Wallet / Explorer -------

    // The network the open wallet talks to, by preset name.
    function networkNameOf(addr) {
        var a = String(addr || "").replace(/\/+$/, "")
        if (!root.backend || a.length === 0) return ""
        var presets = [[qsTr("Testnet"), root.backend.testnetUrl], [qsTr("Devnet"), root.backend.devnetUrl],
                       [qsTr("Local"), root.backend.localhostUrl]]
        for (var i = 0; i < presets.length; ++i)
            if (String(presets[i][1] || "").replace(/\/+$/, "") === a) return presets[i][0]
        return qsTr("Custom")
    }
    // ---- Tabs, by key. Unlocked: the app's six; on the way in: back to the wallet, or Explorer.
    property string currentTab: "wallet"
    signal tabReselected(string key)
    readonly property var tabKeys: d.isWalletOpen
        ? ["balance", "send", "bridge", "explorer", "settings"]
        : ["wallet", "explorer"]
    readonly property var tabTitles: ({ balance: qsTr("Accounts"), send: qsTr("Send"), bridge: qsTr("Bridge"),
                                        explorer: qsTr("Explorer"),
                                        settings: qsTr("Settings"), wallet: qsTr("Wallet") })
    // A tab that isn't on the bar any more (the wallet opened or closed) falls back to the first.
    onTabKeysChanged: if (tabKeys.indexOf(currentTab) < 0) currentTab = tabKeys[0]
    onCurrentTabChanged: if (currentTab === "explorer") explorerLoader.active = true

    // The Explorer, at a page: it loads on its first visit.
    function showInExplorer(open) {
        root.currentTab = "explorer"
        explorerLoader.active = true
        Qt.callLater(function () { if (explorerLoader.item) open(explorerLoader.item) })
    }

    // The frame belongs to the app, not to the way in: the welcome, unlock and setup screens
    // stay full screen (their card offers the Explorer instead).
    readonly property bool frameShown: d.isWalletOpen || currentTab === "explorer"

    ColumnLayout {
        id: frameHeader
        visible: root.frameShown
        height: visible ? implicitHeight : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: Theme.spacing.xlarge
        anchors.rightMargin: Theme.spacing.xlarge
        anchors.topMargin: Theme.spacing.large
        spacing: Theme.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.medium

            // Title row as in the other wallet apps: the name and its help, a line under it.
            ColumnLayout {
                spacing: 2
                RowLayout {
                    spacing: Theme.spacing.small
                    LogosText {
                        objectName: "lezAppTitle"
                        text: qsTr("LEZ")
                        color: Theme.palette.text
                        font.pixelSize: 28
                        font.weight: Theme.typography.weightBold
                    }
                    LogosInfoButton {
                        objectName: "lezAppHelp"
                        title: qsTr("LEZ")
                        Accessible.name: qsTr("Help: LEZ")
                        text: qsTr("Your wallet on the Logos Execution Zone and an explorer for it. "
                                   + "Public accounts are visible on chain; private ones are known only "
                                   + "to you, and transfers between them are proved on this computer. "
                                   + "The Explorer needs no wallet: it reads the chain from your node.")
                    }
                }
                LogosText {
                    objectName: "lezAppSubtitle"
                    text: qsTr("Your LEZ accounts, transfers and the chain.")
                    color: Theme.palette.textSecondary
                    font.pixelSize: Theme.typography.secondaryText
                }
            }

            Item { Layout.fillWidth: true }

            // The network chip, as in the other wallet apps: the network and its sync state, in
            // the state's colour (a test network is orange when all is well); details on hover,
            // Settings on a click.
            LogosBadge {
                id: networkChip
                objectName: "networkChip"
                readonly property string name: root.networkNameOf(root.backend ? root.backend.sequencerAddr : "")
                readonly property bool problem: root.backend !== null && root.backend.syncProblem.length > 0
                readonly property bool syncing: root.backend !== null && root.backend.currentBlockHeight > 0
                                                && root.backend.currentBlockHeight - root.backend.lastSyncedBlock > 10
                // A few blocks behind is normal between polls: only a real catch-up reads as syncing.
                Layout.alignment: Qt.AlignVCenter
                visible: d.isWalletOpen && name.length > 0
                text: name + " · " + (problem ? qsTr("Not syncing") : syncing ? qsTr("Syncing") : qsTr("Synced"))
                color: problem ? Theme.palette.error : syncing ? Theme.palette.warning : Theme.palette.accentOrange
                HoverHandler { id: networkChipHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.currentTab = "settings" }
                ToolTip.visible: networkChipHover.hovered
                ToolTip.delay: 400
                ToolTip.text: (root.backend ? root.backend.sequencerAddr : "")
                              + (root.backend && root.backend.syncProblem.length ? "\n" + root.backend.syncProblem : "")
            }
        }

        LogosTabBar {
            id: appTabs
            objectName: "lezAppTabs"
            Layout.fillWidth: true
            currentIndex: Math.max(0, root.tabKeys.indexOf(root.currentTab))
            Repeater {
                model: root.tabKeys
                LogosTabButton {
                    required property string modelData
                    objectName: "lezTab_" + modelData
                    text: root.tabTitles[modelData]
                    // Clicking the tab you're on goes to its start (an account's page back to
                    // the list), as a tab does in the other wallets.
                    onClicked: {
                        if (root.currentTab === modelData) root.tabReselected(modelData)
                        root.currentTab = modelData
                    }
                }
            }
        }
    }

    // The Explorer tab: works with no wallet open; loaded on its first visit.
    Loader {
        id: explorerLoader
        objectName: "lezExplorerLoader"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: frameHeader.bottom
        anchors.bottom: parent.bottom
        visible: root.currentTab === "explorer"
        active: false
        sourceComponent: ExplorerView { walletBackend: root.backend }
    }

    StackView {
        id: stackView
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: root.frameShown ? frameHeader.bottom : parent.top
        anchors.topMargin: root.frameShown ? Theme.spacing.small : 0
        anchors.bottom: parent.bottom
        visible: root.currentTab !== "explorer"

        Component {
            id: loadingView
            LoadingView {}
        }

        Component {
            id: onboardingView
            OnboardingView {
                id: onboarding

                devnetUrl: backend ? backend.devnetUrl : ""
                testnetUrl: backend ? backend.testnetUrl : ""
                localhostUrl: backend ? backend.localhostUrl : ""
                // A saved wallet: the home screen asks for its password; "I already have a
                // wallet" starts from its paths.
                savedWallet: d.needsPassword
                savedConfigPath: backend ? backend.configPath : ""
                savedStoragePath: backend ? backend.storagePath : ""

                onUnlockWallet: function(password) {
                    if (!backend) return
                    onboarding.unlockBusy = true
                    // "" on success, the reason otherwise; a wrong password stays on the home screen.
                    logos.watch(backend.unlockSaved(password),
                        function(errorMessage) {
                            onboarding.unlockBusy = false
                            if (errorMessage) onboarding.unlockFailed(errorMessage)
                            else d.updateStack(d.isWalletOpen)
                        },
                        function(error) {
                            onboarding.unlockBusy = false
                            onboarding.unlockFailed(qsTr("Error opening wallet: %1").arg(error))
                        }
                    )
                }
                onExploreRequested: root.showInExplorer(function (ex) { ex.goHome() })
                onDefaultPathsWanted: {
                    if (!backend) return
                    logos.watch(backend.defaultWalletDirectory(),
                        function(dir) { if (dir) onboarding.offerDefaultPaths(dir) },
                        function(error) {})
                }

                onCreateWallet: function(password, sequencerUrl) {
                    if (!backend) return
                    onboarding.createError = ""
                    onboarding.busyMessage = qsTr("Creating your wallet…")
                    onboarding.busy = true
                    logos.watch(backend.createNew(password, sequencerUrl),
                        function(raw) {
                            onboarding.busy = false
                            var result = {}
                            try {
                                result = JSON.parse(raw)
                            } catch (e) {
                                onboarding.createError = qsTr("Unexpected response while creating wallet.")
                                d.updateStack(d.isWalletOpen)
                                return
                            }
                            if (!result.success) {
                                onboarding.createError = result.error || qsTr("Failed to create wallet.")
                                d.updateStack(d.isWalletOpen)
                                return
                            }
                            onboarding.showRecoveryPhrase(result.mnemonic || "")
                        },
                        function(error) {
                            onboarding.busy = false
                            onboarding.createError = qsTr("Error creating wallet: %1").arg(error)
                            d.updateStack(d.isWalletOpen)
                        }
                    )
                }

                onOpenWallet: function(configPath, storagePath, password) {
                    if (!backend) return
                    onboarding.openError = ""
                    onboarding.busyMessage = qsTr("Opening your wallet…")
                    onboarding.busy = true
                    // Empty string on success, human-readable message otherwise.
                    logos.watch(backend.openExisting(configPath, storagePath, password),
                        function(errorMessage) {
                            onboarding.busy = false
                            if (errorMessage)
                                onboarding.openError = errorMessage
                            else
                                d.updateStack(d.isWalletOpen)
                        },
                        function(error) {
                            onboarding.busy = false
                            onboarding.openError = qsTr("Error opening wallet: %1").arg(error)
                        }
                    )
                }

                onMnemonicAcknowledged: d.updateStack(d.isWalletOpen)
            }
        }

        Component {
            id: mainView
            AppView {
                id: dashboardView
                page: root.currentTab
                walletBackend: root.backend
                networkName: root.networkNameOf(backend ? backend.sequencerAddr : "")
                storagePath: backend ? backend.storagePath : ""
                accountModel: root.accountModel
                publicAccountModel: root.publicAccountModel
                privateAccountModel: root.privateAccountModel
                lastSyncedBlock: backend ? backend.lastSyncedBlock : 0
                currentBlockHeight: backend ? backend.currentBlockHeight : 0
                onTabRequested: (key) => root.currentTab = key
                Connections {
                    target: root
                    function onTabReselected(key) { if (key === "balance") dashboardView.openAccountId = "" }
                }
                onViewTxInExplorerRequested: (txHash) => root.showInExplorer(function (ex) { ex.navigateTx(txHash) })
                onViewAccountInExplorerRequested: (id) => root.showInExplorer(function (ex) { ex.navigateAccount(id) })
                sequencerAddr: backend ? backend.sequencerAddr : ""
                syncProblem: backend ? backend.syncProblem : ""
                networkPresets: backend ? [{ name: "Devnet", url: backend.devnetUrl },
                                           { name: "Testnet", url: backend.testnetUrl },
                                           { name: "Localhost", url: backend.localhostUrl }] : []

                onCreatePublicAccountRequested: {
                    if (!backend) { console.warn("backend is null"); return }
                    // accountModel updates via NOTIFY when the backend's refreshAccounts()
                    // runs after creation.
                    logos.watch(backend.createAccountPublic(),
                        null,
                        function(error) { console.warn("createAccountPublic failed:", error) })
                }
                onCreatePrivateAccountRequested: {
                    if (!backend) { console.warn("backend is null"); return }
                    logos.watch(backend.createAccountPrivate(),
                        null,
                        function(error) { console.warn("createAccountPrivate failed:", error) })
                }
                onFetchBalancesRequested: {
                    if (!backend) { console.warn("backend is null"); return }
                    backend.refreshBalances()  // void slot, fire-and-forget
                }
                onTransferPublicRequested: (fromId, toAddress, amount) => {
                    if (!backend) return
                    logos.watch(backend.transferPublic(fromId, toAddress, amount),
                        function(raw) { ffiErrors.applyTransferResult(dashboardView, raw) },
                        function(error) {
                            dashboardView.transferResult = qsTr("Error: %1").arg(error)
                            dashboardView.transferResultIsError = true
                            dashboardView.transferTxHash = ""
                        })
                }
                onTransferPrivateRequested: (fromId, toKeysJsonOrAddress, amount) => {
                    if (!backend) return
                    dashboardView.transferPending = true
                    logos.watch(backend.transferPrivate(fromId, toKeysJsonOrAddress, amount),
                        function(raw) { dashboardView.transferPending = false; ffiErrors.applyTransferResult(dashboardView, raw) },
                        function(error) {
                            dashboardView.transferPending = false
                            dashboardView.transferResult = qsTr("Error: %1").arg(error)
                            dashboardView.transferResultIsError = true
                            dashboardView.transferTxHash = ""
                        })
                }
                onTransferPrivateOwnedRequested: (fromId, toAccountId, amount) => {
                    if (!backend) return
                    dashboardView.transferPending = true
                    logos.watch(backend.transferPrivateOwned(fromId, toAccountId, amount),
                        function(raw) { dashboardView.transferPending = false; ffiErrors.applyTransferResult(dashboardView, raw) },
                        function(error) {
                            dashboardView.transferPending = false
                            dashboardView.transferResult = qsTr("Error: %1").arg(error)
                            dashboardView.transferResultIsError = true
                            dashboardView.transferTxHash = ""
                        })
                }
                onTransferShieldedRequested: (fromId, toKeysJsonOrAddress, amount) => {
                    if (!backend) return
                    dashboardView.transferPending = true
                    logos.watch(backend.transferShielded(fromId, toKeysJsonOrAddress, amount),
                        function(raw) { dashboardView.transferPending = false; ffiErrors.applyTransferResult(dashboardView, raw) },
                        function(error) {
                            dashboardView.transferPending = false
                            dashboardView.transferResult = qsTr("Error: %1").arg(error)
                            dashboardView.transferResultIsError = true
                            dashboardView.transferTxHash = ""
                        })
                }
                onTransferShieldedOwnedRequested: (fromId, toAccountId, amount) => {
                    if (!backend) return
                    dashboardView.transferPending = true
                    logos.watch(backend.transferShieldedOwned(fromId, toAccountId, amount),
                        function(raw) { dashboardView.transferPending = false; ffiErrors.applyTransferResult(dashboardView, raw) },
                        function(error) {
                            dashboardView.transferPending = false
                            dashboardView.transferResult = qsTr("Error: %1").arg(error)
                            dashboardView.transferResultIsError = true
                            dashboardView.transferTxHash = ""
                        })
                }
                onTransferDeshieldedRequested: (fromId, toAccountId, amount) => {
                    if (!backend) return
                    dashboardView.transferPending = true
                    logos.watch(backend.transferDeshielded(fromId, toAccountId, amount),
                        function(raw) { dashboardView.transferPending = false; ffiErrors.applyTransferResult(dashboardView, raw) },
                        function(error) {
                            dashboardView.transferPending = false
                            dashboardView.transferResult = qsTr("Error: %1").arg(error)
                            dashboardView.transferResultIsError = true
                            dashboardView.transferTxHash = ""
                        })
                }
                onBridgeWithdrawRequested: (fromId, bedrockAccountPkHex, amount) => {
                    if (!backend) return
                    logos.watch(backend.bridgeWithdraw(fromId, bedrockAccountPkHex, amount),
                        function(raw) { ffiErrors.applyTransferResult(dashboardView, raw) },
                        function(error) {
                            dashboardView.transferResult = qsTr("Error: %1").arg(error)
                            dashboardView.transferResultIsError = true
                            dashboardView.transferTxHash = ""
                        })
                }
                onLabelRequested: (accountId, isPublic) => {
                    setLabelDialog.accountId = accountId
                    setLabelDialog.isPublic = isPublic
                    setLabelDialog.open()
                }
            }
        }
    }
}
