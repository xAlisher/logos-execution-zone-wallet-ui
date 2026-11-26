import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Logos.Controls
import Logos.Theme
import "../components"

Item {
    id: page

    property var explorer
    readonly property var backend: explorer ? explorer.backend : null
    property var blockId: 0

    property var block: ({})
    property bool loaded: false

    Component.onCompleted: page.fetch()

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight
        clip: true

        ColumnLayout {
            id: col
            width: parent.width
            spacing: Theme.spacing.medium

            ExSectionHeader { title: "Block #" + page.blockId }

            LogosText {
                visible: !page.loaded
                text: "Loading…"
                color: Theme.palette.textMuted
                font.pixelSize: Theme.typography.secondaryText
            }

            LogosText {
                visible: page.loaded && Object.keys(page.block).length === 0
                text: "Block not found."
                color: Theme.palette.textMuted
                font.pixelSize: Theme.typography.secondaryText
            }

            ExCard {
                Layout.fillWidth: true
                visible: page.loaded && Object.keys(page.block).length > 0

                ExInfoRow { label: "Block ID"; value: String(page.block.blockId !== undefined ? page.block.blockId : "") }
                ExInfoRow { label: "Hash"; value: page.block.hash || ""; mono: true; copyable: true }

                // Previous hash — a clickable link to the previous block when not genesis.
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacing.medium
                    ExFieldLabel { text: "Previous Hash" }
                    ExMonoText {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        text: page.block.prevBlockHash || ""
                        color: page.blockId > 1 ? Theme.palette.primary : Theme.palette.text
                        font.underline: page.blockId > 1 && prevHover.hovered
                        HoverHandler { id: prevHover; enabled: page.blockId > 1 }
                        TapHandler {
                            enabled: page.blockId > 1
                            onTapped: page.explorer.navigateBlock(Number(page.blockId) - 1)
                        }
                    }
                    ExCopyButton {
                        visible: (page.block.prevBlockHash || "").length > 0
                        value: page.block.prevBlockHash || ""
                        Layout.alignment: Qt.AlignTop
                    }
                }

                ExInfoRow { label: "Timestamp"; value: page.block.timestampText || "" }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacing.medium
                    ExFieldLabel { text: "Status" }
                    ExStatusBadge { status: page.block.status || "Pending"; Layout.alignment: Qt.AlignTop }
                    Item { Layout.fillWidth: true }
                }

                ExInfoRow { label: "Transactions"; value: String(page.block.txCount !== undefined ? page.block.txCount : 0) }
            }

            ExSectionHeader {
                visible: page.loaded && page.block.transactions !== undefined && page.block.transactions.length > 0
                title: "Transactions (" + (page.block.transactions ? page.block.transactions.length : 0) + ")"
            }

            Repeater {
                model: page.block.transactions !== undefined ? page.block.transactions : []
                delegate: ExTxRow {
                    Layout.fillWidth: true
                    tx: modelData
                    onClicked: page.explorer.navigateTx(modelData.hash)
                }
            }

            Item { Layout.preferredHeight: Theme.spacing.large }
        }
    }

    function fetch() {
        if (!page.backend)
            return;
        logos.watch(page.backend.getBlockById(String(page.blockId)),
            function (result) {
                page.block = result || ({});
                page.loaded = true;
            },
            function (err) {
                page.block = ({});
                page.loaded = true;
            });
    }
}
