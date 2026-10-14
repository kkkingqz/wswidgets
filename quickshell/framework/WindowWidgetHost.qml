import QtQuick
import QtQuick.Controls.Basic
import Quickshell

Scope {
    id: root
    required property var definition
    required property WidgetController controller
    readonly property var widgetState: controller.state.widgets[definition.id]
    property alias surface: window
    property alias widgetContext: content.widgetContext
    readonly property bool loaded: content.loaded
    readonly property real progress: window.visible ? 1 : 0
    readonly property bool scrollRequired: scroll.contentHeight > scroll.availableHeight
    function scheduleSize() {
        if (window.backingWindowVisible)
            Qt.callLater(syncSize,widgetState.requestId);
    }
    function syncSize(requestId) {
        if (window.backingWindowVisible && widgetState.requestId===requestId)
            controller.dispatch({type:"RESIZED",id:definition.id,requestId,width:window.width,height:window.height});
    }
    FloatingWindow {
        id: window
        title: "workstation-widgets:" + root.definition.id
        visible: root.controller.state.adapter.connected && root.widgetState.phase!=="closed" && content.loaded
        color: Style.background
        implicitWidth: root.widgetState.panelWidth
        implicitHeight: root.widgetState.panelHeight
        minimumSize: Qt.size(root.widgetState.minimumWidth,root.widgetState.minimumHeight)
        // Native decorations supply move/resize, close, maximize and minimize.
        // Leave maximumSize and native window type to the window system.
        onWidthChanged: root.scheduleSize()
        onHeightChanged: root.scheduleSize()
        onBackingWindowVisibleChanged: root.scheduleSize()
        onClosed: content.widgetContext.requestClose()
        ScrollView {
            id: scroll
            anchors.fill: parent; anchors.margins: Style.padding
            clip: true
            contentWidth: availableWidth
            contentHeight: body.height
            Item {
                id: body
                width: scroll.availableWidth
                height: Math.max(scroll.availableHeight,childrenRect.height)
                Shortcut {
                    sequence: "Escape"
                    context: Qt.WindowShortcut
                    enabled: window.visible
                    onActivated: content.widgetContext.requestClose()
                }
            }
        }
        WidgetContent {
            id: content
            parent: body
            definition: root.definition; controller: root.controller
            availableWidth: scroll.availableWidth
            availableHeight: scroll.availableHeight
            devicePixelRatio: window.devicePixelRatio
        }
    }
}
