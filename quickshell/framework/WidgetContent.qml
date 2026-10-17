import QtQuick

Loader {
    id: root
    required property var definition
    required property WidgetController controller
    required property real availableWidth
    required property real availableHeight
    required property real devicePixelRatio
    readonly property var widgetState: controller.state.widgets[definition.id]
    readonly property bool loaded: status === Loader.Ready
    property bool loadRequested: false
    width: Math.max(0, availableWidth)
    onWidgetStateChanged: reconcileLoad()
    Component.onCompleted: reconcileLoad()
    function reconcileLoad() {
        if (!widgetState) return;
        if (widgetState.phase === "preparing") loadRequested = true;
        else if (widgetState.phase === "closed" && definition.unloadOnClose === true) loadRequested = false;
    }
    onLoadRequestedChanged: {
        if (loadRequested) Qt.callLater(loadContent);
        else source = "";
    }
    function loadContent() {
        if (loadRequested && status === Loader.Null)
            setSource(Qt.resolvedUrl("../" + definition.component), {context: widgetContext});
    }
    property QtObject widgetContext: QtObject {
        readonly property string widgetId: root.definition.id
        readonly property real contentWidth: Math.max(0,root.availableWidth)
        readonly property real contentHeight: Math.max(0,root.availableHeight)
        readonly property real devicePixelRatio: root.devicePixelRatio
        readonly property string phase: root.widgetState.phase
        readonly property color background: Style.background
        readonly property color foreground: Style.foreground
        readonly property color mutedForeground: Style.mutedForeground
        readonly property font font: Style.font
        readonly property string colorScheme: Style.scheme
        function requestClose() { root.controller.command("hide",widgetId); }
    }
    onStatusChanged: {
        if (status === Loader.Error)
            controller.dispatch({type:"AVAILABLE",id:definition.id,value:false,reason:"QML component failed"});
    }
}
