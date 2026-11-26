import QtQuick

import "../qrcodegen.js" as QrGen

// A QR code drawn as plain rectangles, as the Ethereum wallet draws its Receive code: the
// sandbox an app runs in refuses data: URIs and remote images, and a Canvas never paints
// inside the plugin's widget, so the code is encoded in JavaScript and laid out here.
Rectangle {
    id: root

    property string text: ""
    // The size it aims for; the cells are whole pixels, so the code comes out a little smaller.
    property int targetSize: 220
    readonly property bool valid: !!qr

    readonly property var qr: {
        if (!visible || text.length === 0) return null
        try { return QrGen.modules(text) } catch (e) { return null }
    }
    readonly property int quiet: 4
    // Whole pixels: a fractional cell leaves seams that a scanner reads as module edges.
    readonly property int cell: qr ? Math.max(1, Math.floor(targetSize / (qr.size + quiet * 2))) : 0

    // One rectangle per run of dark modules in a row, not one per module.
    readonly property var runs: {
        var out = []
        if (!qr) return out
        for (var y = 0; y < qr.size; y++) {
            var x = 0
            while (x < qr.size) {
                if (qr.bits.charAt(y * qr.size + x) !== "1") { x++; continue }
                var start = x
                while (x < qr.size && qr.bits.charAt(y * qr.size + x) === "1") x++
                out.push([start, y, x - start])
            }
        }
        return out
    }

    // Literal colours, not Theme: an inverted code (dark theme) does not scan.
    color: "#ffffff"
    radius: 4
    implicitWidth: qr ? cell * (qr.size + quiet * 2) : 0
    implicitHeight: implicitWidth

    Repeater {
        model: root.runs
        Rectangle {
            required property var modelData
            x: (modelData[0] + root.quiet) * root.cell
            y: (modelData[1] + root.quiet) * root.cell
            width: modelData[2] * root.cell
            height: root.cell
            color: "#000000"
        }
    }
}
