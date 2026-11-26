import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Logos.Theme
import Logos.Controls
import "../controls"

// The Balance tab: a section for public accounts and one for private ones, each a title, what
// it is for and an add button, then a row per account as the Keycard and Signer apps show one
// (accountkit's AccountDetails). No header of its own: the
// network is the badge in the app's title row, and the wallet refreshes itself.
Item {
    id: root

    // --- Public API: data in ---
    property var publicAccountModel: null
    property var privateAccountModel: null
    property int lastSyncedBlock: 0
    property int currentBlockHeight: 0
    // Why the wallet isn't keeping up, in words; "" when it is.
    property string syncProblem: ""

    // A few blocks behind is normal between polls (every 15 s): only a real catch-up shows.
    readonly property bool syncing: currentBlockHeight > 0 && currentBlockHeight - lastSyncedBlock > 10
    property int syncStartBlock: 0
    onSyncingChanged: if (syncing) syncStartBlock = lastSyncedBlock

    // --- Public API: signals out ---
    signal createPublicAccountRequested()
    signal createPrivateAccountRequested()
    signal labelRequested(string accountId, bool isPublic)
    signal viewAccountInExplorerRequested(string accountIdBase58)
    signal accountOpened(string accountId)

    // The row on screen for an account, so its page can follow its name and balance live.
    // Rows are rebuilt when the account list changes (a new or renamed account): rowsVersion
    // moves then, and a binding through rowFor() looks again.
    property int rowsVersion: 0
    function rowFor(accountId) {
        void rowsVersion
        var cards = [publicCard, privateCard]
        for (var c = 0; c < cards.length; ++c) {
            var rep = cards[c].rows
            for (var i = 0; i < rep.count; ++i) {
                var r = rep.itemAt(i)
                if (r && r.accountId === accountId) return r
            }
        }
        return null
    }

    component AccountsCard: ColumnLayout {
        id: card
        property string title: ""
        property string description: ""
        property string addLabel: ""
        property string emptyText: ""
        property var accountsModel: null
        property bool isPublic: true
        signal addClicked()
        readonly property alias rows: rowRepeater

        Layout.fillWidth: true
        spacing: Theme.spacing.small

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.small
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                LogosText {
                    text: card.title
                    font.pixelSize: Theme.typography.titleText
                    font.weight: Theme.typography.weightBold
                }
                LogosText {
                    Layout.fillWidth: true
                    text: card.description
                    wrapMode: Text.WordWrap
                    color: Theme.palette.textSecondary
                    font.pixelSize: Theme.typography.secondaryText
                }
            }
            LogosButton {
                objectName: card.isPublic ? "lezCreatePublicButton" : "lezCreatePrivateButton"
                Layout.alignment: Qt.AlignTop
                compact: true
                text: card.addLabel
                onClicked: card.addClicked()
            }
        }

        LogosText {
            visible: rowRepeater.count === 0
            Layout.topMargin: Theme.spacing.small
            text: card.emptyText
            color: Theme.palette.textSecondary
            font.pixelSize: Theme.typography.secondaryText
        }

        Repeater {
            id: rowRepeater
            model: card.accountsModel
            onItemAdded: root.rowsVersion++
            onItemRemoved: root.rowsVersion++
            delegate: AccountRow {
                Layout.fillWidth: true
                name: model.name ?? ""
                accountId: model.accountId ?? ""
                balance: model.balance ?? ""
                isPublic: model.isPublic ?? card.isPublic
                keysJson: model.keysJson ?? ""
                onLabelRequested: (id, pub) => root.labelRequested(id, pub)
                onViewInExplorerRequested: (id) => root.viewAccountInExplorerRequested(id)
                onOpened: root.accountOpened(accountId)
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
            spacing: Theme.spacing.xlarge

            LogosNotice {
                objectName: "lezSyncProblem"
                Layout.fillWidth: true
                visible: message.length > 0
                severity: LogosNotice.Warning
                message: root.syncProblem
                shown: message.length > 0
            }

            // A strip, as the Keycard card shows a connection: only while the wallet scans,
            // because private accounts and their balances fill in as it goes.
            Rectangle {
                objectName: "lezSyncProgress"
                Layout.fillWidth: true
                visible: root.syncing
                radius: 6
                color: Theme.palette.backgroundSecondary
                implicitHeight: syncColumn.implicitHeight + 2 * Theme.spacing.small
                ColumnLayout {
                    id: syncColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Theme.spacing.medium
                    anchors.rightMargin: Theme.spacing.medium
                    spacing: Theme.spacing.tiny
                    RowLayout {
                        Layout.fillWidth: true
                        LogosText {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            text: qsTr("Scanning blocks: private accounts and balances may be "
                                       + "missing until it finishes.")
                            color: Theme.palette.textSecondary
                            font.pixelSize: Theme.typography.secondaryText
                        }
                        LogosText {
                            text: root.lastSyncedBlock + " / " + root.currentBlockHeight
                            font.family: Theme.typography.mono
                            color: Theme.palette.textSecondary
                            font.pixelSize: Theme.typography.secondaryText
                        }
                    }
                    LogosProgressBar {
                        Layout.fillWidth: true
                        from: root.syncStartBlock
                        to: Math.max(root.currentBlockHeight, root.syncStartBlock + 1)
                        value: root.lastSyncedBlock
                        trackColor: Theme.palette.backgroundElevated
                    }
                }
            }

            AccountsCard {
                id: publicCard
                objectName: "lezPublicAccountsCard"
                title: qsTr("Public")
                description: qsTr("Seen on chain. Use one to receive deposits and public transfers.")
                addLabel: qsTr("New account")
                emptyText: qsTr("No public accounts yet.")
                accountsModel: root.publicAccountModel
                isPublic: true
                onAddClicked: root.createPublicAccountRequested()
            }

            AccountsCard {
                id: privateCard
                objectName: "lezPrivateAccountsCard"
                Layout.topMargin: Theme.spacing.large
                title: qsTr("Private")
                description: qsTr("Hidden on chain. To receive privately, share an account's keys.")
                addLabel: qsTr("New account")
                emptyText: root.syncing ? qsTr("Looking for your private accounts…")
                                        : qsTr("No private accounts yet.")
                accountsModel: root.privateAccountModel
                isPublic: false
                onAddClicked: root.createPrivateAccountRequested()
            }

            Item { Layout.preferredHeight: Theme.spacing.small }
        }
    }
}
