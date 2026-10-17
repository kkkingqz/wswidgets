pragma Singleton
import QtQuick
import "theme.mjs" as Theme
QtObject {
    property SystemPalette systemPalette: SystemPalette { colorGroup: SystemPalette.Active }
    property SystemPalette disabledPalette: SystemPalette { colorGroup: SystemPalette.Disabled }
    property var theme: null
    // light, dark or empty: the desktop scheme from wsdbus (Desktop.qml).
    property string scheme: ""
    property bool animationsEnabled: true
    readonly property int gutter: 12
    readonly property int padding: 16
    readonly property int radius: 16
    readonly property int animationMs: 300
    readonly property color background: theme ? theme.background : systemPalette.window
    readonly property color foreground: theme ? theme.foreground : systemPalette.windowText
    readonly property color mutedForeground: Qt.rgba(foreground.r, foreground.g, foreground.b, foreground.a * 0.7)
    readonly property var buttonMetrics: theme?.buttons?.metrics || {
        radius: 8, paddingTop: 8, paddingRight: 16, paddingBottom: 8, paddingLeft: 16,
        minimumHeight: 36, transitionMs: 120
    }
    readonly property var textFont: theme?.font || {
        family: Qt.application.font.family,
        pixelSize: logicalFontSize(Qt.application.font),
        weight: Qt.application.font.weight, italic: Qt.application.font.italic
    }
    readonly property var buttonFont: theme?.buttons?.font || textFont
    // Grouped bindings preserve fractional point sizes; Qt.font() truncates them.
    property font font
    font.family: textFont.family
    font.pointSize: textFont.pixelSize * 72 / 96
    font.weight: textFont.weight
    font.italic: textFont.italic
    function logicalFontSize(font) {
        // Qt's pixelSize getter rounds point fonts; keep their original precision.
        return font.pointSize > 0 ? font.pointSize * 96 / 72 : font.pixelSize;
    }
    function buttonAppearance(enabled, hovered, down, checked, focus) {
        if (theme?.buttons) return theme.buttons.states[Theme.buttonStateKey(enabled, hovered, down, checked, focus)];
        const palette = enabled ? systemPalette : disabledPalette;
        let bg = checked ? palette.highlight : palette.button;
        const fg = checked ? palette.highlightedText : palette.buttonText;
        if (enabled && (down || hovered)) bg = Qt.tint(bg, Qt.rgba(fg.r, fg.g, fg.b, down ? 0.16 : 0.08));
        return {background: bg, foreground: fg, borderColor: palette.mid, borderWidth: 1,
            focusColor: palette.highlight, focusWidth: enabled && focus ? 2 : 0};
    }
    function applyTheme(value) {
        if (!Theme.validateTheme(value) || JSON.stringify(theme) === JSON.stringify(value)) return;
        theme = value;
    }
}
