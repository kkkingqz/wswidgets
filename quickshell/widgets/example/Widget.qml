import QtQuick
import QtQuick.Controls
import "../../controls" as Ui
Item {
    required property QtObject context
    implicitHeight: Math.max(420, content.implicitHeight)
    Column {
        id: content
        width: parent.width; spacing: 20
        Ui.Label { objectName: "titleLabel"; text: "Workstation widgets"; fontScale: 1.5; font.weight: Font.Bold; width: parent.width; wrapMode: Text.Wrap }
        Ui.Label { objectName: "bodyLabel"; text: "Общий контейнер • отдельное содержимое"; color: context.mutedForeground; width: parent.width; wrapMode: Text.WordWrap }
        Ui.Label { text: "Размер содержимого: " + context.contentWidth + " × " + context.contentHeight + "\nМасштаб Qt: " + context.devicePixelRatio + "\nСостояние: " + context.phase; width: parent.width; wrapMode: Text.Wrap }
        Ui.Button { objectName: "closeButton"; text: "Закрыть"; width: Math.min(implicitWidth, parent.width); onClicked: context.requestClose() }
    }
}
