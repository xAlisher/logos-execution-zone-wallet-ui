import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Logos.Theme
import Logos.Controls
import Logos.Icons

import "../controls"
import "../Base58.js" as Base58
import "../Format.js" as Format
import "../Units.js" as Units

// Send: the transfer type (which also teaches the four kinds LEZ has), then From, To and
// Amount, each on its own panel, then Send.
Item {
    id: root

    // --- Public API: data in ---
    property var publicAccountModel: null
    property var privateAccountModel: null
    property bool transferPending: false

    // --- Public API: signals out (match backend: transfer_public, transfer_private, transfer_private_owned, transfer_shielded, transfer_shielded_owned, transfer_deshielded) ---
    signal transferPublicRequested(string fromAccountId, string toAddress, string amount)
    signal transferPrivateRequested(string fromAccountId, string toKeysJsonOrAddress, string amount)
    signal transferPrivateOwnedRequested(string fromAccountId, string toAccountId, string amount)
    signal transferShieldedRequested(string fromAccountId, string toKeysJsonOrAddress, string amount)
    signal transferShieldedOwnedRequested(string fromAccountId, string toAccountId, string amount)
    signal transferDeshieldedRequested(string fromAccountId, string toAccountId, string amount)

    // From an account's page: its kind's transfer type (Public, or Private for a private
    // account) with the account as "from". The person can still change both.
    function preselect(accountId, isPublic) {
        transferTypeBar.currentIndex = isPublic ? 0 : 1
        // The From list swaps models with the type: pick once it holds the new one.
        Qt.callLater(function () {
            var i = fromCombo.indexOfValue(accountId)
            if (i >= 0) fromCombo.currentIndex = i
        })
    }

    readonly property int fromFilterCount: fromCombo.count
    // The selected type pill's text size, which the form labels (and Bridge's) take.
    readonly property int labelPixelSize: transferTypeBar.font.pixelSize

    QtObject {
        id: d
        readonly property bool isPublicTab: transferTypeBar.currentIndex === 0
        readonly property bool isPrivateTab: transferTypeBar.currentIndex === 1
        readonly property bool isShieldedTab: transferTypeBar.currentIndex === 2
        readonly property bool isDeshieldedTab: transferTypeBar.currentIndex === 3
        // Where the money comes from and goes to, for each type.
        readonly property bool fromPrivate: isPrivateTab || isDeshieldedTab
        readonly property bool toPrivate: isPrivateTab || isShieldedTab

        // One of your own accounts picked as the recipient (hex), with its name for the field.
        property string ownTo: ""
        property string ownToName: ""

        readonly property string fromId: root.fromFilterCount > 0 && fromCombo.currentIndex >= 0
                                         ? (fromCombo.currentValue ?? "")
                                         : Base58.decode(manualFromField.text.trim())
        readonly property string typed: toField.text.trim()
        // A pasted recipient: a public address, or private keys as JSON.
        readonly property bool toValid: ownTo.length > 0
            || (toPrivate ? isValidKeysJson(typed) : typed.length > 0)
        readonly property bool sendEnabled: !root.transferPending
                                            && amountField.text.length > 0 && toValid
                                            && fromId.length > 0

        readonly property var descriptions: [
            qsTr("Public to public. Both accounts and the amount are visible on chain."),
            qsTr("Private to private. Nothing about it is visible on chain: not who, not how much."),
            qsTr("Public to private. The amount leaving your public account is visible; who gets it isn't."),
            qsTr("Private to public. The amount arriving at the public account is visible; who sent it isn't.")
        ]

        function clearTo() {
            ownTo = ""
            ownToName = ""
            toField.readOnly = false
            toField.text = ""
        }
        function pickOwn(accountId, name) {
            ownTo = accountId
            ownToName = name
            toField.text = name + "  ·  " + Format.shortenMiddle(Base58.encode(accountId))
            toField.readOnly = true
        }

        // Private and shielded transfers to someone else are made out to their keys:
        // {nullifier_public_key, viewing_public_key}, as Copy keys on an account gives them.
        function isValidKeysJson(text) {
            var trimmed = (text || "").trim()
            if (trimmed.length === 0) return false
            var obj
            try {
                obj = JSON.parse(trimmed)
            } catch (e) {
                return false
            }
            return !!obj && typeof obj === "object" && !Array.isArray(obj)
                && typeof obj.nullifier_public_key === "string" && obj.nullifier_public_key.length > 0
                && typeof obj.viewing_public_key === "string" && obj.viewing_public_key.length > 0
        }
    }

    // The recipient kind changes with the type, and a picked account may now be the sender.
    Connections {
        target: transferTypeBar
        function onCurrentIndexChanged() { d.clearTo() }
    }
    Connections {
        target: fromCombo
        function onCurrentValueChanged() { if (d.ownTo === fromCombo.currentValue) d.clearTo() }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacing.medium

        // Transfer type toggle — pill-shaped, so this secondary row reads as a
        // level below the underlined section bar above it.
        PillTabBar {
            id: transferTypeBar
            Layout.fillWidth: true
            spacing: Theme.spacing.small
            currentIndex: 0

            PillTabButton { text: qsTr("Public") }
            PillTabButton { text: qsTr("Private") }
            PillTabButton { text: qsTr("Shielded") }
            PillTabButton { text: qsTr("Deshielded") }
        }

        // What the chosen type does, so the four read as a lesson as well as a choice.
        LogosText {
            objectName: "lezSendTypeDescription"
            Layout.fillWidth: true
            Layout.bottomMargin: Theme.spacing.medium
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: d.descriptions[Math.max(0, transferTypeBar.currentIndex)]
            color: Theme.palette.textSecondary
            font.pixelSize: Theme.typography.secondaryText
        }

        // From: your accounts of the type's sending kind, or an ID typed in when there are none.
        FieldBlock {
            label: qsTr("From")
            labelPixelSize: transferTypeBar.font.pixelSize

            LogosTextField {
                id: manualFromField
                Layout.fillWidth: true
                placeholderText: qsTr("Paste or type from account ID")
                visible: root.fromFilterCount === 0
                Component.onCompleted: backgroundItem.color = Theme.palette.backgroundInset
            }

            AccountComboBox {
                id: fromCombo
                objectName: "lezSendFrom"
                Layout.fillWidth: true
                model: d.fromPrivate ? root.privateAccountModel : root.publicAccountModel
                visible: root.fromFilterCount > 0
            }
        }

        // To: paste someone's address (or keys), or pick one of your own accounts. Either way
        // one recipient, cleared with the round x.
        FieldBlock {
            label: qsTr("To")
            labelPixelSize: transferTypeBar.font.pixelSize

            RowLayout {
                id: toRow
                Layout.fillWidth: true
                spacing: Theme.spacing.small

                LogosTextField {
                    id: toField
                    objectName: "lezSendTo"
                    Layout.fillWidth: true
                    rightPadding: clearTo.visible ? clearTo.width + 16 : 12
                    placeholderText: d.toPrivate ? qsTr("Recipient's keys")
                                                 : qsTr("Recipient's address")
                    Component.onCompleted: backgroundItem.color = Theme.palette.backgroundInset

                    // The round x: back to an empty field.
                    Rectangle {
                        id: clearTo
                        objectName: "lezSendToClear"
                        visible: toField.text.length > 0
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 20; height: 20; radius: 10
                        color: clearHover.hovered ? Theme.palette.backgroundButton : Theme.palette.backgroundTertiary
                        LogosIcon {
                            anchors.centerIn: parent
                            width: 10; height: 10
                            source: LogosIcons.close
                            color: Theme.palette.text
                        }
                        HoverHandler { id: clearHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: d.clearTo() }
                    }
                }

                LogosButton {
                    id: myAccountsButton
                    objectName: "lezSendMyAccounts"
                    text: qsTr("My accounts")
                    enabled: ownList.count > 0
                    onClicked: ownPopup.open()
                }
            }

            LogosText {
                Layout.fillWidth: true
                visible: d.toPrivate && d.ownTo.length === 0 && d.typed.length > 0 && !d.toValid
                text: qsTr("Paste the recipient's keys, as Copy keys on their private account gives "
                           + "them. A private account's address can't be paid.")
                font.pixelSize: Theme.typography.secondaryText
                color: Theme.palette.error
                wrapMode: Text.WordWrap
            }

            // Your accounts that can receive this type, without the one sending.
            Popup {
                id: ownPopup
                // Under the field and its button, as wide as both.
                parent: toRow
                y: toRow.height + 4
                width: toRow.width
                padding: 4
                background: Rectangle {
                    radius: 6
                    color: Theme.palette.backgroundSecondary
                    border.color: Theme.palette.border
                }
                contentItem: ListView {
                    id: ownList
                    implicitHeight: Math.min(contentHeight, 300)
                    clip: true
                    model: d.toPrivate ? root.privateAccountModel : root.publicAccountModel
                    delegate: ItemDelegate {
                        id: ownOption
                        required property var model
                        readonly property bool isSender: model.accountId === d.fromId
                        width: ListView.view.width
                        visible: !isSender
                        height: isSender ? 0 : implicitHeight
                        leftPadding: Theme.spacing.medium
                        rightPadding: Theme.spacing.medium
                        background: Rectangle {
                            color: ownOption.hovered ? Theme.palette.backgroundTertiary : "transparent"
                            radius: 4
                        }
                        contentItem: RowLayout {
                            spacing: Theme.spacing.small
                            LogosText {
                                text: fromCombo.nameFor(ownOption.model.name, ownOption.model.accountId)
                                textFormat: Text.PlainText
                            }
                            LogosText {
                                text: Format.shortenMiddle(Base58.encode(ownOption.model.accountId || ""))
                                color: Theme.palette.textSecondary
                                font.family: Theme.typography.mono
                                font.pixelSize: Theme.typography.secondaryText
                            }
                            Item { Layout.fillWidth: true }
                            LogosText {
                                text: ownOption.model.balance ? Units.format(ownOption.model.balance) : "—"
                                color: Theme.palette.primary
                                font.pixelSize: Theme.typography.secondaryText
                            }
                        }
                        onClicked: {
                            d.pickOwn(ownOption.model.accountId,
                                      fromCombo.nameFor(ownOption.model.name, ownOption.model.accountId))
                            ownPopup.close()
                        }
                    }
                }
            }
        }

        // Amount, with the token named inside the field and what the sender has under it.
        FieldBlock {
            label: qsTr("Amount")
            labelPixelSize: transferTypeBar.font.pixelSize

            LogosTextField {
                id: amountField
                objectName: "lezSendAmount"
                Layout.fillWidth: true
                rightPadding: unitLabel.implicitWidth + 24
                // Follows the locale too: the validator refuses the other
                // separator, so a hardcoded "0.00" would show an example the
                // field will not accept wherever ',' is the decimal point.
                placeholderText: "0" + Qt.locale().decimalPoint + "00"
                validator: RegularExpressionValidator { regularExpression: Units.inputRegExp() }
                Component.onCompleted: backgroundItem.color = Theme.palette.backgroundInset

                LogosText {
                    id: unitLabel
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: Units.SYMBOL
                    color: Theme.palette.textSecondary
                    font.pixelSize: Theme.typography.secondaryText
                }
            }

            RowLayout {
                objectName: "lezSendAvailable"
                visible: fromCombo.visible && fromCombo.currentBalance.length > 0
                spacing: 4
                LogosText {
                    text: Units.format(fromCombo.currentBalance)
                    color: Theme.palette.primary
                    font.pixelSize: Theme.typography.secondaryText
                }
                LogosText {
                    text: qsTr("available")
                    color: Theme.palette.textSecondary
                    font.pixelSize: Theme.typography.secondaryText
                }
            }
        }

        LogosButton {
            objectName: "lezSendButton"
            Layout.fillWidth: true
            text: qsTr("Send")
            font.pixelSize: Theme.typography.secondaryText
            enabled: d.sendEnabled
            onClicked: {
                var fromId = d.fromId
                var amount = Units.normalizeInput(amountField.text.trim())
                var own = d.ownTo.length > 0
                // A picked account goes by its ID; a pasted public address is decoded from
                // Base58; pasted keys go as they are.
                var to = own ? d.ownTo : (d.toPrivate ? d.typed : Base58.decode(d.typed))
                if (fromId.length === 0 || to.length === 0 || amount.length === 0) return
                if (d.isPublicTab)
                    root.transferPublicRequested(fromId, to, amount)
                else if (d.isPrivateTab)
                    own ? root.transferPrivateOwnedRequested(fromId, to, amount)
                        : root.transferPrivateRequested(fromId, to, amount)
                else if (d.isShieldedTab)
                    own ? root.transferShieldedOwnedRequested(fromId, to, amount)
                        : root.transferShieldedRequested(fromId, to, amount)
                else if (d.isDeshieldedTab)
                    root.transferDeshieldedRequested(fromId, to, amount)
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
