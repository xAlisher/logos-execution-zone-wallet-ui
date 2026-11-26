import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Logos.Theme
import Logos.Controls
import "../Base58.js" as Base58
import "../Format.js" as Format
import "../Units.js" as Units

// Picks one of your accounts. Closed: its name and short address. Open: one line per account,
// name, short address and balance; nothing to act on, since picking is the only thing to do
// here (copy and the explorer are on the Accounts tab). The first account is picked as soon as
// there is one, so a form never starts on an empty choice.
LogosComboBox {
    id: root

    // Pick the first account whenever the list fills or changes under an empty choice.
    property bool autoSelectFirst: true

    function nameFor(name, accountId) {
        return name && name.length > 0
               ? name : qsTr("Account %1").arg(Format.shortenHead(Base58.encode(accountId || "")))
    }

    // Balance by account, read from the same model, for "N available" under an amount.
    Instantiator {
        id: rowsInfo
        model: root.model
        delegate: QtObject {
            required property var model
            readonly property string accountId: model.accountId || ""
            readonly property string balance: model.balance || ""
        }
    }
    function balanceOf(accountId) {
        for (var i = 0; i < rowsInfo.count; ++i) {
            var o = rowsInfo.objectAt(i)
            if (o && o.accountId === accountId) return o.balance
        }
        return ""
    }
    readonly property string currentBalance: { void rowsInfo.count; return currentValue ? balanceOf(currentValue) : "" }

    // Inputs sit a shade darker than the panel they are on.
    Component.onCompleted: {
        if (backgroundItem) backgroundItem.color = Theme.palette.backgroundInset
        if (autoSelectFirst && count > 0 && currentIndex < 0) currentIndex = 0
    }

    textRole: "name"
    valueRole: "accountId"
    displayText: currentIndex >= 0 && currentValue
                 ? nameFor(currentText, currentValue) + "  ·  " + Format.shortenMiddle(Base58.encode(currentValue))
                 : ""

    implicitHeight: 40

    onCountChanged: if (autoSelectFirst && count > 0 && currentIndex < 0) currentIndex = 0

    Binding {
        target: root.popupItem
        property: "implicitHeight"
        value: Math.min(root.popupListView.contentHeight + 2, 300)
    }

    delegate: ItemDelegate {
        id: option
        required property int index
        required property var model
        width: root.popupItem ? root.popupItem.availableWidth : root.width
        highlighted: root.highlightedIndex === index
        hoverEnabled: true
        leftPadding: Theme.spacing.medium
        rightPadding: Theme.spacing.medium
        topPadding: Theme.spacing.small
        bottomPadding: Theme.spacing.small

        background: Rectangle {
            color: option.highlighted || option.hovered ? Theme.palette.backgroundTertiary : "transparent"
            radius: 4
        }

        contentItem: RowLayout {
            spacing: Theme.spacing.small
            LogosText {
                Layout.minimumWidth: 0
                Layout.maximumWidth: Math.ceil(implicitWidth)
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.nameFor(option.model.name, option.model.accountId)
                textFormat: Text.PlainText
                font.bold: option.index === root.currentIndex
            }
            LogosText {
                text: Format.shortenMiddle(Base58.encode(option.model.accountId || ""))
                textFormat: Text.PlainText
                color: Theme.palette.textSecondary
                font.family: Theme.typography.mono
                font.pixelSize: Theme.typography.secondaryText
            }
            Item { Layout.fillWidth: true }
            LogosText {
                text: option.model.balance && option.model.balance.length > 0
                      ? Units.format(option.model.balance) : "—"
                textFormat: Text.PlainText
                color: Theme.palette.primary
                font.pixelSize: Theme.typography.secondaryText
            }
        }
    }
}
