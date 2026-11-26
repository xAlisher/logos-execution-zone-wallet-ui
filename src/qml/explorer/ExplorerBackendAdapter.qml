import QtQuick

// The explorer pages' `backend`: lez-explorer-ui's names, forwarded to the LEZ app backend's
// explorer* PROPs and SLOTs. Used by the Explorer tab and by the Explorer block in Settings.
QtObject {
    id: adapter
    property var walletBackend: null

        readonly property var recentBlocks: adapter.walletBackend ? adapter.walletBackend.explorerRecentBlocks : []
        readonly property var chainHeight: adapter.walletBackend ? adapter.walletBackend.explorerChainHeight : 0
        readonly property string connectionStatus: adapter.walletBackend ? adapter.walletBackend.explorerConnectionStatus : ""
        readonly property var syncStatus: adapter.walletBackend ? adapter.walletBackend.explorerSyncStatus : ({})
        readonly property string configText: adapter.walletBackend ? adapter.walletBackend.explorerConfigText : ""
        readonly property string defaultConfig: adapter.walletBackend ? adapter.walletBackend.explorerDefaultConfig : ""
        function applyConfigJson(json) { return adapter.walletBackend.explorerApplyConfigJson(json) }
        function resetSequencerCache() { return adapter.walletBackend.explorerResetSequencerCache() }
        function refreshBlocks() { return adapter.walletBackend.explorerRefreshBlocks() }
        function loadMoreBlocks() { return adapter.walletBackend.explorerLoadMoreBlocks() }
        function getBlockById(id) { return adapter.walletBackend.explorerGetBlockById(id) }
        function getBlockByHash(hash) { return adapter.walletBackend.explorerGetBlockByHash(hash) }
        function getTransaction(hash) { return adapter.walletBackend.explorerGetTransaction(hash) }
        function getAccount(accountId) { return adapter.walletBackend.explorerGetAccount(accountId) }
        function getTransactionsByAccount(accountId, offset, limit) {
            return adapter.walletBackend.explorerGetTransactionsByAccount(accountId, offset, limit)
        }
        function search(query) { return adapter.walletBackend.explorerSearch(query) }
    }
