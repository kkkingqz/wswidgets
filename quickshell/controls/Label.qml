import QtQuick
import QtQuick.Controls.Basic as Basic
import "../framework" as Framework

Basic.Label {
    property real fontScale: 1.0
    color: Framework.Style.foreground
    font.family: Framework.Style.font.family
    font.pointSize: Framework.Style.font.pointSize * fontScale
    font.weight: Framework.Style.font.weight
    font.italic: Framework.Style.font.italic
}
