import QtQuick
import Quickshell
import Quickshell.Io
import "desktop.mjs" as Desktop

// Desktop facts from wsdbus (`wsdbus-ctl --json watch`, path in
// WIDGETS_DESKTOP_CTL): the lock screen hides the popups, the colour scheme
// reaches the widgets (Style.scheme). Without the variable nothing runs and
// the facts keep their defaults; the watcher restarts when it exits.
Scope {
    id: root
    required property WidgetController controller
    property string ctl: Quickshell.env("WIDGETS_DESKTOP_CTL") || ""
    property var facts: Desktop.initialDesktop
    readonly property bool connected: facts.connected
    readonly property bool locked: facts.locked
    readonly property string scheme: facts.scheme
    onLockedChanged: if (locked) controller.command("hidePopups", "")
    onSchemeChanged: Style.scheme = scheme
    Process {
        id: watch
        command: [root.ctl, "--json", "watch"]
        running: root.ctl !== ""
        stdout: SplitParser { onRead: line => root.facts = Desktop.applyDesktopLine(root.facts, line) }
        onExited: { root.facts = Desktop.initialDesktop; restart.start(); }
    }
    Timer { id: restart; interval: 2000; onTriggered: watch.running = root.ctl !== "" }
}
