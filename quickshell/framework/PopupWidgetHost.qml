import QtQuick
import Quickshell
import "../adapters/gnome"
Scope {
    id: root
    required property var definition
    required property WidgetController controller
    readonly property var widgetState: controller.state.widgets[definition.id]
    property alias surface: window
    property alias widgetContext: content.widgetContext
    readonly property bool loaded: content.loaded
    readonly property real progress: frame.progress
    readonly property bool scrollRequired: frame.scrollRequired
    GnomePopupWindow {
        id: window
        widgetId: root.definition.id
        widgetState: root.widgetState
        adapterReady: root.controller.state.adapter.connected
        mask: Region { x: Style.gutter; y: Style.gutter; width: frame.width; height: Math.floor(frame.revealedHeight); radius: Style.radius }
        onClosed: content.widgetContext.requestClose()
        PopupFrame {
            id: frame
            x: Style.gutter; y: Style.gutter
            width: root.widgetState.panelWidth; height: root.widgetState.panelHeight
            widgetId: root.definition.id; widgetState: root.widgetState; controller: root.controller
            focus: true
            Keys.onEscapePressed: event => { content.widgetContext.requestClose(); event.accepted = true; }
        }
        WidgetContent {
            id: content
            parent: frame.body
            definition: root.definition; controller: root.controller
            availableWidth: root.widgetState.panelWidth - Style.padding * 2
            availableHeight: root.widgetState.panelHeight - Style.padding * 2
            devicePixelRatio: window.devicePixelRatio
        }
    }
}
