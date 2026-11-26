import QtQuick
import QtQuick.Layouts

import Logos.Theme
import Logos.Controls

// Step 2: which sequencer the wallet talks to. Its own screen because the
// answer is written into the wallet's config at creation — after this step it
// is not a preference any more. A meaning first (choice cards, as in the
// Blockchain app); a raw URL field only for Custom.
ColumnLayout {
    id: root

    property string devnetUrl: ""
    property string testnetUrl: ""
    property string localhostUrl: ""

    // "testnet", "devnet", "localhost" or "custom". Testnet is the public network a release
    // ships against; devnet is the developers' pre-release network.
    property string choice: "testnet"

    readonly property string sequencerUrl: {
        switch (choice) {
        case "devnet":    return root.devnetUrl
        case "testnet":   return root.testnetUrl
        case "localhost": return root.localhostUrl
        default:          return customUrlField.text.trim()
        }
    }
    readonly property bool valid: sequencerUrl.length > 0

    readonly property string hint: valid ? "" : qsTr("Enter a sequencer URL to continue")

    spacing: Theme.spacing.medium

    LogosText {
        text: qsTr("Select your network")
        color: Theme.palette.text
        font.pixelSize: OnboardingText.stepHeading
        font.weight: Theme.typography.weightBold
    }

    LogosText {
        Layout.fillWidth: true
        text: qsTr("Your wallet submits transactions through a sequencer.")
        color: Theme.palette.textSecondary
        font.pixelSize: Theme.typography.secondaryText
        wrapMode: Text.WordWrap
    }

    OnboardingChoiceCard {
        objectName: "lezNetworkTestnetCard"
        Layout.fillWidth: true
        title: qsTr("Testnet")
        badge: qsTr("Recommended")
        description: qsTr("The public test network.")
        selected: root.choice === "testnet"
        onPicked: root.choice = "testnet"
    }

    OnboardingChoiceCard {
        objectName: "lezNetworkDevnetCard"
        Layout.fillWidth: true
        visible: root.devnetUrl.length > 0
        title: qsTr("Devnet")
        description: qsTr("Pre-release network for testing upcoming LEZ versions.")
        selected: root.choice === "devnet"
        onPicked: root.choice = "devnet"
    }

    OnboardingChoiceCard {
        objectName: "lezNetworkLocalhostCard"
        Layout.fillWidth: true
        title: qsTr("Local sequencer")
        description: qsTr("A sequencer you run on this machine (%1).")
                         .arg(root.localhostUrl.replace(/^https?:\/\//, ""))
        selected: root.choice === "localhost"
        onPicked: root.choice = "localhost"
    }

    OnboardingChoiceCard {
        objectName: "lezNetworkCustomCard"
        Layout.fillWidth: true
        title: qsTr("Custom")
        description: qsTr("Another sequencer, by its URL.")
        selected: root.choice === "custom"
        onPicked: root.choice = "custom"

        LogosTextField {
            id: customUrlField
            objectName: "lezCreateSequencerField"
            Layout.fillWidth: true
            visible: root.choice === "custom"
            placeholderText: qsTr("Sequencer URL, e.g. https://sequencer.example:3040")
            onVisibleChanged: if (visible) forceActiveFocus()
        }
    }

    Item { Layout.fillHeight: true }
}
