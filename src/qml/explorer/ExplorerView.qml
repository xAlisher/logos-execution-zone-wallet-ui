import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Logos.Controls
import Logos.Theme
import "components"

// The LEZ app's Explorer tab: lez-explorer-ui's view (main @ release/0.4.0 merge), inside the
// wallet's module. Its pages still read `explorer.backend`; here that is an adapter onto the
// wallet backend's explorer* PROPs and SLOTs, so the pages are unchanged. Works with no
// wallet open.
Rectangle {
    id: root
    color: Theme.palette.background

    // The LEZ app's backend replica (LEZWalletBackend).
    property var walletBackend: null
    readonly property bool ready: walletBackend !== null

    // What the explorer pages call `backend`: the same names, forwarded.
    readonly property QtObject backend: ExplorerBackendAdapter { walletBackend: root.walletBackend }

    // Self-managed navigation history (browser-style back/forward). Each entry
    // is a descriptor { type, param?, query? }.
    property var history: []
    property int histIndex: -1

    // --- Navigation API (pages call these via the injected `explorer`; the Wallet tab too) ---
    function sameDescriptor(a, b) {
        if (!a || !b)
            return false;
        if (a.type !== b.type)
            return false;
        if (a.type === "home")
            return true;
        if (a.type === "search")
            return a.query === b.query;
        return a.param === b.param;
    }
    function navigateTo(desc) {
        var current = root.histIndex >= 0 ? root.history[root.histIndex] : null;
        if (root.sameDescriptor(current, desc))
            return;
        var h = root.history.slice(0, root.histIndex + 1);
        h.push(desc);
        root.history = h;
        root.histIndex = h.length - 1;
        root.render();
    }
    function navigateBlock(id) { root.navigateTo({ type: "block", param: id }); }
    function navigateTx(hash) { root.navigateTo({ type: "tx", param: hash }); }
    function navigateAccount(id) { root.navigateTo({ type: "account", param: id }); }
    function navigateSettings() { root.navigateTo({ type: "settings" }); }
    function showSearchResults(results, query) {
        root.navigateTo({ type: "search", param: results, query: query });
    }
    function goHome() { root.navigateTo({ type: "home" }); }
    function goBack() { if (root.histIndex > 0) { root.histIndex--; root.render(); } }
    function goForward() { if (root.histIndex < root.history.length - 1) { root.histIndex++; root.render(); } }

    function render() {
        if (root.histIndex < 0)
            return;
        var d = root.history[root.histIndex];
        var props = { explorer: root };
        var url = "pages/ExHomePage.qml";
        if (d.type === "block") {
            url = "pages/ExBlockPage.qml";
            props.blockId = d.param;
        } else if (d.type === "tx") {
            url = "pages/ExTransactionPage.qml";
            props.txHash = d.param;
        } else if (d.type === "account") {
            url = "pages/ExAccountPage.qml";
            props.accountId = d.param;
        } else if (d.type === "search") {
            url = "pages/ExSearchResultsPage.qml";
            props.results = d.param;
            props.query = d.query || "";
        } else if (d.type === "settings") {
            url = "pages/ExSettingsPage.qml";
        }
        pageLoader.setSource(Qt.resolvedUrl(url), props);
        navBar.canGoBack = root.histIndex > 0;
        navBar.canGoForward = root.histIndex < root.history.length - 1;
    }

    Component.onCompleted: root.goHome()

    readonly property var syncStatus: root.backend.syncStatus
    readonly property string syncError: (syncStatus && syncStatus.error) ? syncStatus.error : ""
    readonly property string syncState: (syncStatus && syncStatus.state) ? syncStatus.state : ""
    readonly property bool errorLooksUnreachable: {
        var e = root.syncError.toLowerCase();
        if (e === "")
            return false;
        return e.indexOf("error sending request") >= 0
            || e.indexOf("connection refused") >= 0
            || e.indexOf("cannot reach") >= 0
            || e.indexOf("tcp connect error") >= 0
            || e.indexOf("operation timed out") >= 0;
    }

    readonly property bool nodeUnreachable:
        root.errorLooksUnreachable
        && root.syncState !== "Syncing"
        && root.syncState !== "CaughtUp"

    // Raise whoever can manage the node.
    function openBlockchainApp() {
        if (typeof logos === "undefined" || typeof logos.request !== "function")
            return;
        logos.request("basecamp.apps.launch", { app: "blockchain_ui" },
                      function (res) {});
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing.large
        spacing: Theme.spacing.medium

        ExNavigationBar {
            id: navBar
            Layout.fillWidth: true
            onBackClicked: root.goBack()
            onForwardClicked: root.goForward()
            onHomeClicked: root.goHome()
            onSettingsClicked: root.navigateSettings()
        }

        ExSequencerStatusBar {
            syncState: root.syncState
            syncError: root.syncError
            chainHeight: root.backend.chainHeight
            nodeUnreachable: root.nodeUnreachable
            onOpenBlockchainAppRequested: root.openBlockchainApp()
        }

        ExSearchBar {
            Layout.fillWidth: true
            // Only searchable once the sequencer is actually answering.
            enabled: root.backend.connectionStatus === "Connected"
            onSearchRequested: function (query) {
                if (!root.walletBackend || query.trim().length === 0)
                    return;
                logos.watch(root.backend.search(query), function (results) {
                    var blocks = results && results.blocks ? results.blocks : [];
                    var txs = results && results.transactions ? results.transactions : [];
                    var accts = results && results.accounts ? results.accounts : [];
                    var total = blocks.length + txs.length + accts.length;
                    if (total === 1) {
                        if (blocks.length === 1)
                            root.navigateBlock(blocks[0].blockId);
                        else if (txs.length === 1)
                            root.navigateTx(txs[0].hash);
                        else
                            root.navigateAccount(accts[0].accountId);
                    } else {
                        root.showSearchResults(results, query);
                    }
                }, function (err) {
                    root.showSearchResults({ blocks: [], transactions: [], accounts: [] }, query);
                });
            }
        }

        Loader {
            id: pageLoader
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
