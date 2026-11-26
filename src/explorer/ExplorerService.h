#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>

class QTimer;
struct LogosModules;

/**
 * @brief The LEZ block explorer's backend logic, inside the LEZ app's module.
 *
 * Ported from lez-explorer-ui's LezExplorerUiBackend (main @ release/0.4.0 merge).
 * A Basecamp module has one .rep backend, so the explorer can't come in as its own
 * module: the wallet backend owns one of these, forwards its state to `explorer*`
 * PROPs and its lookups to `explorer*` SLOTs. The logic is unchanged; only the
 * PROP setters became plain members (stateChanged() tells the wallet to forward).
 *
 * It owns the read-only sequencer's lifecycle in lez_core (start / stop / reset its
 * cache): one owner in one app, so the wallet and the explorer no longer race over
 * it (lez-explorer-ui#36).
 */
class ExplorerService : public QObject {
    Q_OBJECT
public:
    explicit ExplorerService(LogosModules* modules, QObject* parent = nullptr);
    ~ExplorerService() override;

    // Load the saved (or default) sequencer config, start it, start the tip poll.
    void start();

    bool applyConfigJson(QString json);
    bool resetSequencerCache();
    void refreshBlocks();
    void loadMoreBlocks();
    QVariantMap getBlockById(QString id);
    QVariantMap getBlockByHash(QString hash);
    QVariantMap getTransaction(QString hash);
    QVariantMap getAccount(QString accountId);
    QVariantList getTransactionsByAccount(QString accountId, int offset, int limit);
    QVariantMap search(QString query);

    QVariantList recentBlocks() const { return m_recentBlocksProp; }
    qlonglong chainHeight() const { return m_chainHeight; }
    QString connectionStatus() const { return m_connectionStatus; }
    QVariantMap syncStatus() const { return m_syncStatus; }
    QString configText() const { return m_configText; }
    QString defaultConfig() const { return m_defaultConfig; }

signals:
    void stateChanged();
    void error(QString message);

private:
    // The PROP setters the ported code calls.
    void setRecentBlocks(const QVariantList& v) { m_recentBlocksProp = v; emit stateChanged(); }
    void setChainHeight(qlonglong v) { if (m_chainHeight != v) { m_chainHeight = v; emit stateChanged(); } }
    void setConnectionStatus(const QString& v) { if (m_connectionStatus != v) { m_connectionStatus = v; emit stateChanged(); } }
    void setSyncStatus(const QVariantMap& v) { if (m_syncStatus != v) { m_syncStatus = v; emit stateChanged(); } }
    void setConfigText(const QString& v) { if (m_configText != v) { m_configText = v; emit stateChanged(); } }
    void setDefaultConfig(const QString& v) { m_defaultConfig = v; emit stateChanged(); }

    void pollTip();
    quint64 applySyncStatus(const QString& json);
    void resetPollBaseline();
    void clearBlockFeed();
    QVariantMap fetchBlock(quint64 blockId);
    QVariantList parseBlockArrayJson(const QString& json) const;

    QString configFilePath();
    bool writeConfigFile(const QString& json);
    QString readConfigFile() const;
    bool startSequencerFromFile();

    LogosModules* m_modules = nullptr;

    QVariantList m_recentBlocksProp;
    qlonglong m_chainHeight = 0;
    QString m_connectionStatus;
    QVariantMap m_syncStatus;
    QString m_configText;
    QString m_defaultConfig;

    QString m_configFilePath;
    QString m_lastStartError;
    int m_autoStartRetriesLeft = 0;
    QVariantList m_recentBlocks;
    quint64 m_newestLoadedId = 0;
    quint64 m_oldestLoadedId = 0;
    quint64 m_lastPolledTip = 0;
    bool m_polledOnce = false;
    QTimer* m_pollTimer = nullptr;
};
