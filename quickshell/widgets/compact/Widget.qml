import QtQuick
import QtQuick.Controls
import "../../controls" as Ui
Item {
    required property QtObject context
    implicitHeight: Math.max(160, content.implicitHeight)
    Column {
        id: content
        width: parent.width; spacing: 16
        Ui.Label { objectName: "titleLabel"; text: "Компактный виджет"; fontScale: 1.5; width: parent.width; wrapMode: Text.Wrap }
        Ui.Label { objectName: "bodyLabel"; text: "Тот же framework, другой Item."; color: context.mutedForeground; width: parent.width; wrapMode: Text.WordWrap }
        Ui.Button { objectName: "closeButton"; text: "Закрыть"; width: Math.min(implicitWidth, parent.width); onClicked: context.requestClose() }
    }
}
