import QtQuick
import QtQuick.Layouts

import Logos.Theme
import Logos.Controls

import "../explorer"
import "../explorer/pages"

// Settings: the wallet's network and file (set when it was created, shown here so they can
// be checked), and the Explorer's local sequencer config (what used to sit behind its gear).
// A Lock button comes once lez_core can close a wallet.
ColumnLayout {
    id: root

    property var walletBackend: null
    property string networkName: ""
    property string sequencerAddr: ""
    property string storagePath: ""

    spacing: Theme.spacing.medium

    LogosText {
        text: qsTr("Settings")
        color: Theme.palette.text
        font.pixelSize: Theme.typography.titleText
        font.weight: Theme.typography.weightBold
    }

    LogosFrame {
        objectName: "lezSettingsWallet"
        Layout.fillWidth: true
        contentItem: ColumnLayout {
            spacing: Theme.spacing.small
            LogosText {
                text: qsTr("Wallet")
                color: Theme.palette.text
                font.weight: Theme.typography.weightBold
            }
            LogosText {
                Layout.fillWidth: true
                text: qsTr("Network: %1").arg(root.networkName.length ? root.networkName : qsTr("unknown"))
                color: Theme.palette.textSecondary
                font.pixelSize: Theme.typography.secondaryText
            }
            LogosCopyableText {
                Layout.fillWidth: true
                text: root.sequencerAddr
                copyText: root.sequencerAddr
                showCopyButton: root.sequencerAddr.length > 0
            }
            LogosText {
                Layout.fillWidth: true
                Layout.topMargin: Theme.spacing.small
                text: qsTr("File")
                color: Theme.palette.textSecondary
                font.pixelSize: Theme.typography.secondaryText
            }
            LogosCopyableText {
                Layout.fillWidth: true
                text: root.storagePath
                copyText: root.storagePath
                showCopyButton: root.storagePath.length > 0
            }
            LogosText {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTr("The network is set when a wallet is created. To use another one, create "
                           + "a wallet on it.")
                color: Theme.palette.textTertiary
                font.pixelSize: Theme.typography.secondaryText
            }
        }
    }

    // The Explorer's own settings page, unchanged (it calls explorer.goHome() after a save). It
    // reads its config once, as it is created: so only once the backend has one to give.
    Loader {
        objectName: "lezSettingsExplorer"
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.topMargin: Theme.spacing.small
        active: root.walletBackend !== null && root.walletBackend.explorerDefaultConfig.length > 0
        sourceComponent: ExSettingsPage {
            explorer: QtObject {
                readonly property QtObject backend: ExplorerBackendAdapter { walletBackend: root.walletBackend }
                function goHome() {}
            }
        }
    }
}
