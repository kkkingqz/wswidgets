import QtQuick
import Quickshell
Scope {
    id: root
    required property var definition
    required property WidgetController controller
    readonly property var surface: host.item?.surface || null
    readonly property var widgetContext: host.item?.widgetContext || null
    readonly property bool loaded: host.item?.loaded || false
    readonly property real progress: host.item?.progress || 0
    readonly property bool scrollRequired: host.item?.scrollRequired || false
    Loader {
        id: host
        sourceComponent: root.definition.presentation === "window" ? normalHost : popupHost
    }
    Component { id: popupHost; PopupWidgetHost { definition: root.definition; controller: root.controller } }
    Component { id: normalHost; WindowWidgetHost { definition: root.definition; controller: root.controller } }
}
