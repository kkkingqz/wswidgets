import QtQuick
import Quickshell
import "framework"

// Desktop.qml against a fake wsdbus-ctl (check-qml.py): the snapshot sets
// the scheme, the lock hides the open popup, a removed fact resets.
ShellRoot {
    WidgetController {
        id: controller
        entries: [{id: "example", enabled: true, width: 420, height: 580}]
        testNow: 0
    }
    Desktop { id: desktop; controller: controller }
    property int stage: 0
    Timer {
        interval: 20; repeat: true; running: true
        property int ticks: 0
        onTriggered: {
            if (++ticks > 200) { console.error(`desktop facts timed out at stage ${stage}`); Qt.exit(1); }
            const example = controller.state.widgets.example;
            if (stage === 0 && desktop.connected && Style.scheme === "dark" && !desktop.locked) {
                controller.dispatch({type: "ADAPTER_CONNECTED"});
                controller.command("show", "example");
                controller.dispatch({type: "PLACED", id: "example", requestId: example.requestId});
                stage = 1;
            } else if (stage === 1 && desktop.locked) {
                if (example.desiredOpen || example.phase === "open") { console.error("lock kept the popup"); Qt.exit(1); }
                stage = 2;
            } else if (stage === 2 && Style.scheme === "") {
                console.log("Desktop facts: scheme, lock and removal passed");
                Qt.exit(0);
            }
        }
    }
}
