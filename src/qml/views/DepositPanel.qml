import QtQuick
import QtQuick.Layouts

import Logos.Theme
import Logos.Controls

import "../controls"
import "../Base58.js" as Base58
import "../Format.js" as Format
import "../Units.js" as Units

// L1 → LEZ. A deposit is made in the Blockchain app (Wallet → Channel Deposit), not here, so
// this walks through that app's form one action at a time, in its order and its words, and
// hands over the two values it needs.
//
// The Blockchain app has no recipient field. The recipient travels in the deposit's
// metadata, which LEZ reads as borsh DepositMetadata { recipient: Identified(Key(pk)) }:
// 0x01 (Identified), 0x00 (Key), then the account's 32-byte public key, in base58.
ColumnLayout {
    id: root

    spacing: Theme.spacing.medium

    property var publicAccountModel: null
    property var walletBackend: null
    property string channelId: ""
    // The wallet's network ("Testnet", "Devnet", ...): the deposit must be made on the Logos
    // Blockchain that network's LEZ runs on.
    property string networkName: ""
    property int labelPixelSize: Theme.typography.primaryText

    property string publicKeyHex: ""
    readonly property string metadata: publicKeyHex.length === 64
                                       ? Base58.encode("0100" + publicKeyHex) : ""
    readonly property bool onTestnet: networkName === "Testnet"

    function loadKey() {
        root.publicKeyHex = ""
        if (!root.walletBackend || !accountPicker.currentValue) return
        logos.watch(root.walletBackend.getPublicAccountKey(accountPicker.currentValue),
            function (key) { root.publicKeyHex = /^[0-9a-fA-F]{64}$/.test(key || "") ? key.toLowerCase() : "" },
            function (err) { root.publicKeyHex = "" })
    }

    // One action: its number, what to do, then anything it needs.
    component Action: RowLayout {
        id: action
        property int number: 0
        property string text: ""
        default property alias content: actionExtra.data
        Layout.fillWidth: true
        spacing: Theme.spacing.small

        // A plain number, in a fixed column so the text and what follows line up.
        LogosText {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 22
            text: action.number + "."
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.small
            LogosText {
                Layout.fillWidth: true
                text: action.text
                textFormat: Text.StyledText
                wrapMode: Text.WordWrap
            }
            ColumnLayout {
                id: actionExtra
                Layout.fillWidth: true
                spacing: Theme.spacing.small
            }
        }
    }

    // A value to paste elsewhere: in an input-like box, with copy.
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
                text: valueBox.value.length > 0 ? valueBox.value : qsTr("Not known yet")
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

    // Small print under an action.
    component Hint: LogosText {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        color: Theme.palette.textSecondary
        font.pixelSize: Theme.typography.secondaryText
    }


    FieldBlock {
        label: qsTr("In this wallet")
        labelPixelSize: root.labelPixelSize

        Action {
            number: 1
            text: qsTr("Choose the account to receive the deposit.")
            AccountComboBox {
                id: accountPicker
                objectName: "lezDepositAccount"
                Layout.fillWidth: true
                model: root.publicAccountModel
                onCurrentValueChanged: root.loadKey()
            }
            Hint {
                text: qsTr("Deposits arrive public. To make them private, shield them "
                           + "afterwards on Send.")
            }
        }
    }

    FieldBlock {
        label: qsTr("In the Blockchain app")
        labelPixelSize: root.labelPixelSize

        Action {
            number: 2
            text: qsTr("Open the Blockchain app and make sure the node is running.")
            Hint {
                visible: !root.onTestnet
                color: Theme.palette.warning
                text: qsTr("This wallet is on %1: the node must be on the %1 Logos "
                           + "Blockchain, or the deposit won't reach it.")
                      .arg(root.networkName.length ? root.networkName : qsTr("another network"))
            }
        }
        Action {
            number: 3
            text: qsTr("Go to <b>Wallet</b> → <b>Channel Deposit</b>.")
        }
        Action {
            number: 4
            text: qsTr("In <b>Deposit from</b>, pick the account holding the tokens.")
        }
        Action {
            number: 5
            text: qsTr("Tick the notes to deposit and press <b>Next</b>.")
            Hint { text: qsTr("A note goes in whole: its full value is deposited.") }
        }
        Action {
            number: 6
            text: root.onTestnet
                  ? qsTr("In <b>Channel ID hex</b>, tick <b>LEZ testnet</b>, or paste:")
                  : qsTr("In <b>Channel ID hex</b>, paste:")
            Value { objectName: "lezDepositChannel"; value: root.channelId }
            Hint {
                visible: !root.onTestnet
                text: qsTr("Not the \"LEZ testnet\" tick: that is testnet's channel.")
            }
        }
        Action {
            number: 7
            text: qsTr("Leave <b>Change goes to</b> and <b>Accounts funding the gas fee</b> "
                       + "as they are, and enter a <b>Max tx fee</b>.")
        }
        Action {
            number: 8
            text: qsTr("In <b>Metadata</b>, paste:")
            Value { objectName: "lezDepositMetadata"; value: root.metadata }
            Hint {
                text: qsTr("It names your account as the recipient. Without it the deposit "
                           + "doesn't reach you.")
            }
        }
        Action {
            number: 9
            text: qsTr("Press <b>Next</b>, check the review, and press <b>Confirm &amp; deposit</b>.")
        }
    }

    FieldBlock {
        label: qsTr("Then")
        labelPixelSize: root.labelPixelSize

        Action {
            number: 10
            text: qsTr("Wait for it to arrive: about 10 hours. A deposit is credited only "
                           + "once it is final on the Logos Blockchain.")
            RowLayout {
                spacing: 4
                LogosText {
                    text: accountPicker.currentBalance.length > 0
                          ? Units.format(accountPicker.currentBalance) : "—"
                    color: Theme.palette.primary
                    font.pixelSize: Theme.typography.secondaryText
                }
                LogosText {
                    text: qsTr("in this account now")
                    color: Theme.palette.textSecondary
                    font.pixelSize: Theme.typography.secondaryText
                }
            }
        }
    }

}
