import QtQuick
import Quickshell
FloatingWindow {
    id: root
    required property string widgetId
    required property var widgetState
    required property bool adapterReady
    title: "workstation-widgets:" + widgetId
    visible: adapterReady && widgetState.phase !== "closed"
    color: "transparent"
    implicitWidth: widgetState.panelWidth + 24
    implicitHeight: widgetState.panelHeight + 24
    minimumSize: Qt.size(implicitWidth, implicitHeight)
    maximumSize: minimumSize
    // Quickshell creates its backing QQuickWindow lazily. Qt's attached
    // windowChanged runs before it maps: suppress decorations on this surface
    // alone, so ordinary widget windows can retain native frames.
    Item {
        Window.onWindowChanged: {
            if (Window.window)
                Window.window.flags |= Qt.FramelessWindowHint;
        }
    }
}
