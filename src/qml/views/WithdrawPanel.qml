import QtQuick
import QtQuick.Layouts

import Logos.Theme
import Logos.Controls
import Logos.Icons

import "../controls"
import "../Base58.js" as Base58
import "../Units.js" as Units

// Bridge: withdraw from a public LEZ account to a Bedrock (L1) account. Laid out as Send is:
// what it does, then From, To and Amount on their own panels, then the action.
ColumnLayout {
    id: root

    spacing: Theme.spacing.medium

    // --- Public API: data in ---
    property var publicAccountModel: null
    property bool transferPending: false
    // The label size Send's selected type uses, so both forms read alike.
    property int labelPixelSize: Theme.typography.primaryText

    // --- Public API: signals out (match backend: bridge_withdraw) ---
    signal bridgeWithdrawRequested(string fromAccountId, string bedrockAccountPkHex, string amount)

    readonly property int fromFilterCount: fromCombo.count

    QtObject {
        id: d
        readonly property string fromId: root.fromFilterCount > 0 && fromCombo.currentIndex >= 0
                                         ? (fromCombo.currentValue ?? "")
                                         : Base58.decode(manualFromField.text.trim())
        readonly property string to: toField.text.trim()
        readonly property bool sendEnabled: !root.transferPending
                                            && amountField.text.length > 0
                                            && to.length > 0 && fromId.length > 0
    }


    // From: a public account (withdrawals leave from public accounts only).
    FieldBlock {
        label: qsTr("From")
        labelPixelSize: root.labelPixelSize

        LogosTextField {
            id: manualFromField
            Layout.fillWidth: true
            placeholderText: qsTr("Paste or type from account ID")
            visible: root.fromFilterCount === 0
            Component.onCompleted: backgroundItem.color = Theme.palette.backgroundInset
        }

        AccountComboBox {
            id: fromCombo
            objectName: "lezBridgeFrom"
            Layout.fillWidth: true
            model: root.publicAccountModel
            visible: root.fromFilterCount > 0
        }
    }

    // To: the Bedrock account's public key, cleared with the round x.
    FieldBlock {
        label: qsTr("To")
        labelPixelSize: root.labelPixelSize

        LogosTextField {
            id: toField
            objectName: "lezBridgeTo"
            Layout.fillWidth: true
            rightPadding: clearTo.visible ? clearTo.width + 16 : 12
            placeholderText: qsTr("Recipient's Logos Blockchain public key (hex)")
            Component.onCompleted: backgroundItem.color = Theme.palette.backgroundInset

            Rectangle {
                id: clearTo
                objectName: "lezBridgeToClear"
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
                TapHandler { onTapped: toField.text = "" }
            }
        }
    }

    // Amount, the token inside the field, what the account has under it.
    FieldBlock {
        label: qsTr("Amount")
        labelPixelSize: root.labelPixelSize

        LogosTextField {
            id: amountField
            objectName: "lezBridgeAmount"
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
            objectName: "lezBridgeAvailable"
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
        objectName: "lezBridgeWithdraw"
        Layout.fillWidth: true
        text: qsTr("Bridge")
        font.pixelSize: Theme.typography.secondaryText
        enabled: d.sendEnabled
        onClicked: {
            var amount = Units.normalizeInput(amountField.text.trim())
            if (d.fromId.length > 0 && d.to.length > 0 && amount.length > 0)
                root.bridgeWithdrawRequested(d.fromId, d.to, amount)
        }
    }

}
