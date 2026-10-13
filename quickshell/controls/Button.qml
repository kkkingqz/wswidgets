import QtQuick
import QtQuick.Controls.Basic as Basic
import "../framework" as Framework

Basic.Button {
    id: control
    readonly property var appearance: Framework.Style.buttonAppearance(enabled, hovered, down, checked, visualFocus)
    readonly property var metrics: Framework.Style.buttonMetrics
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    implicitHeight: Math.max(metrics.minimumHeight, implicitContentHeight + topPadding + bottomPadding)
    leftPadding: metrics.paddingLeft + appearance.borderWidth
    rightPadding: metrics.paddingRight + appearance.borderWidth
    topPadding: metrics.paddingTop + appearance.borderWidth
    bottomPadding: metrics.paddingBottom + appearance.borderWidth
    font.family: Framework.Style.buttonFont.family
    // pointSize preserves fractional logical sizes (font.pixelSize is an int).
    font.pointSize: Framework.Style.buttonFont.pixelSize * 72 / 96
    font.weight: Framework.Style.buttonFont.weight
    font.italic: Framework.Style.buttonFont.italic
    // Keep Basic's IconLabel: icons, text, Action, mirroring and accessibility
    // retain the standard control behavior. Its color roles share one theme value.
    palette.buttonText: appearance.foreground
    palette.brightText: appearance.foreground
    palette.windowText: appearance.foreground
    palette.highlight: appearance.foreground
    background: Rectangle {
        implicitWidth: 0
        radius: control.metrics.radius
        color: control.appearance.background
        border.color: control.appearance.borderColor
        border.width: control.appearance.borderWidth
        Behavior on color {
            enabled: Framework.Style.animationsEnabled
            ColorAnimation { duration: control.metrics.transitionMs }
        }
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            radius: parent.radius
            border.color: control.appearance.focusColor
            border.width: control.appearance.focusWidth
            visible: border.width > 0
        }
    }
}
