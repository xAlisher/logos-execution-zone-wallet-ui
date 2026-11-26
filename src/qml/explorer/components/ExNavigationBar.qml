import QtQuick
import QtQuick.Layouts
import Logos.Controls
import Logos.Theme

// Top navigation: back / forward / home + title.
RowLayout {
    id: root

    property bool canGoBack: false
    property bool canGoForward: false
    signal backClicked()
    signal forwardClicked()
    signal homeClicked()
    signal settingsClicked()

    spacing: Theme.spacing.small

    ExIconButton {
        source: Qt.resolvedUrl("../icons/arrow-left.svg")
        enabled: root.canGoBack
        text: "Back"
        onClicked: root.backClicked()
    }
    ExIconButton {
        source: Qt.resolvedUrl("../icons/arrow-right.svg")
        enabled: root.canGoForward
        text: "Forward"
        onClicked: root.forwardClicked()
    }
    ExIconButton {
        source: Qt.resolvedUrl("../icons/home.svg")
        text: "Home"
        onClicked: root.homeClicked()
    }

    // No title here: the LEZ app's frame names the app, its tab says Explorer.

    Item { Layout.fillWidth: true }

    // The explorer's settings live in the app's Settings tab now.
    ExIconButton {
        visible: false
        source: Qt.resolvedUrl("../icons/settings.svg")
        text: "Settings"
        onClicked: root.settingsClicked()
    }
}
