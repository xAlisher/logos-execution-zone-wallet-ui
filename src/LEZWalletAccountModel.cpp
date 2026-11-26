#include "LEZWalletAccountModel.h"
#include <QHash>
#include <QPair>
#include <QVariantMap>
#include <algorithm>

LEZWalletAccountModel::LEZWalletAccountModel(QObject* parent)
    : QAbstractListModel(parent)
{
}

int LEZWalletAccountModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid())
        return 0;
    return m_entries.size();
}

QVariant LEZWalletAccountModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_entries.size())
        return QVariant();

    const LEZWalletAccountEntry& e = m_entries.at(index.row());
    switch (role) {
    case NameRole:    return e.name;
    case AccountIdRole:  return e.accountId;
    case BalanceRole: return e.balance;
    case IsPublicRole: return e.isPublic;
    case SectionKeyRole: return e.sectionKey;
    case KeysJsonRole: return e.keysJson;
    case IsFirstInGroupRole: return e.isFirstInGroup;
    case IsFirstPrivateRole: return e.isFirstPrivate;
    default:          return QVariant();
    }
}

QHash<int, QByteArray> LEZWalletAccountModel::roleNames() const
{
    return {
        { NameRole,    "name"    },
        { AccountIdRole, "accountId" },
        { BalanceRole, "balance" },
        { IsPublicRole, "isPublic" },
        { SectionKeyRole, "sectionKey" },
        { KeysJsonRole, "keysJson" },
        { IsFirstInGroupRole, "isFirstInGroup" },
        { IsFirstPrivateRole, "isFirstPrivate" }
    };
}

void LEZWalletAccountModel::replaceFromVariantList(const QVariantList& list)
{
    // Rebuilding from scratch loses any balance already fetched for an account that's
    // still present — carry it over so periodic re-listing (e.g. to pick up newly
    // discovered private accounts) doesn't make balances flicker empty until the next
    // refresh repopulates them.
    QHash<QString, QString> previousBalances;
    previousBalances.reserve(m_entries.size());
    for (const LEZWalletAccountEntry& e : m_entries)
        previousBalances.insert(e.accountId, e.balance);

    QVector<LEZWalletAccountEntry> entries;
    for (const QVariant& v : list) {
        LEZWalletAccountEntry e;
        e.balance = QString();
        e.name = QString();
        if (v.type() == QVariant::Map) {
            const QVariantMap map = v.toMap();
            e.accountId = map.value(QStringLiteral("account_id")).toString();
            e.isPublic = map.value(QStringLiteral("is_public"), true).toBool();
            e.name = map.value(QStringLiteral("name")).toString();
            if (e.isPublic) {
                e.sectionKey = PublicSectionKey;
            } else {
                e.sectionKey = map.value(QStringLiteral("npk")).toString();
                e.keysJson = map.value(QStringLiteral("keys_json")).toString();
            }
        } else {
            e.accountId = v.toString();
            e.isPublic = true;
            e.sectionKey = PublicSectionKey;
        }
        const auto previous = previousBalances.find(e.accountId);
        if (previous != previousBalances.end())
            e.balance = previous.value();
        entries.append(e);
    }
    // Keep entries grouped by section (public first) so consecutive rows of the same
    // group are contiguous, then mark each group's first row for the QML header.
    std::stable_sort(entries.begin(), entries.end(),
        [](const LEZWalletAccountEntry& a, const LEZWalletAccountEntry& b) {
            if (a.isPublic != b.isPublic) return a.isPublic;
            return a.sectionKey < b.sectionKey;
        });
    for (int i = 0; i < entries.size(); ++i) {
        entries[i].isFirstInGroup = (i == 0) || (entries[i].sectionKey != entries[i - 1].sectionKey);
        // All private key-groups sit under a single "Private" title (unlike the public
        // section, they don't each get their own top-level header) — so only the very
        // first private row across all groups needs to flag it.
        entries[i].isFirstPrivate = !entries[i].isPublic && (i == 0 || entries[i - 1].isPublic);
    }

    // The same accounts as on screen (the usual case: a re-list after every sync, so every
    // poll): leave the model alone. A reset rebuilds every row in the view, which flickers.
    const auto same = [](const LEZWalletAccountEntry& a, const LEZWalletAccountEntry& b) {
        return a.accountId == b.accountId && a.isPublic == b.isPublic && a.name == b.name
            && a.sectionKey == b.sectionKey && a.keysJson == b.keysJson;
    };
    if (entries.size() == m_entries.size()
        && std::equal(entries.begin(), entries.end(), m_entries.begin(), same))
        return;

    beginResetModel();
    const int oldCount = m_entries.size();
    m_entries = entries;
    endResetModel();
    if (oldCount != m_entries.size())
        emit countChanged();
}

void LEZWalletAccountModel::setBalanceByAccountId(const QString& accountId, const QString& balance)
{
    for (int i = 0; i < m_entries.size(); ++i) {
        if (m_entries.at(i).accountId == accountId) {
            if (m_entries.at(i).balance != balance) {
                m_entries[i].balance = balance;
                QModelIndex idx = index(i, 0);
                emit dataChanged(idx, idx, { BalanceRole });
            }
            return;
        }
    }
}


bool LEZWalletAccountModel::isPublicAccount(const QString& accountId, bool defaultValue) const
{
    for (const LEZWalletAccountEntry& e : m_entries) {
        if (e.accountId == accountId)
            return e.isPublic;
    }
    return defaultValue;
}
