import QtQuick
import QtQuick.Layouts

import Logos.Theme
import Logos.Controls

import "../controls"
import "../explorer"
import "../explorer/pages"

// Settings, in blocks as Send and Bridge are: the wallet's network and file (set when it was
// created, shown so they can be checked), how to use another wallet or network, and the
// Explorer's settings (which used to sit behind a gear inside the Explorer).
ColumnLayout {
    id: root

    property var walletBackend: null
    property string networkName: ""
    property string sequencerAddr: ""
    property string storagePath: ""
    property int labelPixelSize: Theme.typography.primaryText

    spacing: Theme.spacing.medium

    // A value to check or copy: in an input-like box, the middle elided when it's long.
    component Value: Rectangle {
        id: valueBox
        property string value: ""
        Layout.fillWidth: true
        implicitHeight: 40
        radius: Theme.spacing.radiusSmall
        color: Theme.palette.backgroundInset
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 8
            spacing: 6
            LogosText {
                Layout.fillWidth: true
                elide: Text.ElideMiddle
                text: valueBox.value.length > 0 ? valueBox.value : qsTr("Unknown")
                color: valueBox.value.length > 0 ? Theme.palette.text : Theme.palette.textTertiary
                font.family: Theme.typography.mono
                font.pixelSize: Theme.typography.secondaryText
            }
            LogosCopyButton {
                visible: valueBox.value.length > 0
                value: valueBox.value
            }
        }
    }

    component Note: LogosText {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        color: Theme.palette.textSecondary
        font.pixelSize: Theme.typography.secondaryText
    }

    FieldBlock {
        objectName: "lezSettingsNetwork"
        label: root.networkName.length ? qsTr("Network: %1").arg(root.networkName) : qsTr("Network")
        labelPixelSize: root.labelPixelSize
        Note { text: qsTr("The sequencer this wallet talks to.") }
        Value { value: root.sequencerAddr }
    }

    FieldBlock {
        objectName: "lezSettingsFile"
        label: qsTr("Wallet file")
        labelPixelSize: root.labelPixelSize
        Note { text: qsTr("Where this wallet is kept on this computer.") }
        Value { value: root.storagePath }
    }

    // No button yet: the wallet core can't close an open wallet, so opening or creating
    // another one from here would fail. Once it can, this becomes a button to the start screen.
    FieldBlock {
        objectName: "lezSettingsSwitch"
        label: qsTr("Another wallet or network")
        labelPixelSize: root.labelPixelSize
        Note {
            text: qsTr("A wallet stays open until you quit Basecamp. To use another wallet, or "
                       + "a wallet on another network: quit Basecamp, open it again, open LEZ and "
                       + "choose <b>Create new or unlock other wallet</b>.")
            textFormat: Text.StyledText
        }
    }

    // The Explorer's settings. The page reads its config once, as it is created: so only once
    // the backend has one to give.
    FieldBlock {
        objectName: "lezSettingsExplorer"
        label: qsTr("Explorer")
        labelPixelSize: root.labelPixelSize
        Note {
            text: qsTr("The Explorer rebuilds LEZ blocks from a Logos Blockchain node and the LEZ "
                       + "channel on it. It starts with these settings; Save restarts it.")
        }
        Loader {
            Layout.fillWidth: true
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
}
