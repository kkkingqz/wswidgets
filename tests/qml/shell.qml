import QtQuick
import Quickshell
import "framework"

ShellRoot {
    property var buttonProbe: null
    function findClose(host) {
        function find(item) {
            if (item.objectName === "closeButton") return item;
            for (const child of item.children || []) { const found=find(child); if (found) return found; }
            return null;
        }
        return find(host.surface.contentItem);
    }
    function buttonPalette() {
        const states={};
        for (const key of ["normal","focus","hover","hover+focus","pressed","pressed+focus","pressed+hover","pressed+hover+focus",
            "checked","checked+focus","checked+hover","checked+hover+focus","checked+pressed","checked+pressed+focus","checked+pressed+hover","checked+pressed+hover+focus","disabled"])
            states[key]={background: "#ff203040",foreground:"#fff0f1f2",borderColor:"#ff405060",borderWidth:1,focusColor:"#ffabcdef",focusWidth:key.includes("focus")?2:0};
        states.pressed.background="#ff607080";
        states.disabled.background="#ff102030";
        states.disabled.foreground="#80f0f1f2";
        states.checked.background="#ff8090a0";
        return {background:"#ff36363a",foreground:"#ffffffff",buttons:{states,
            metrics:{radius:12,paddingTop:4,paddingRight:12,paddingBottom:4,paddingLeft:12,minimumHeight:32,transitionMs:150},
            font:{family:"Sans",pixelSize:16,weight:400,italic:false}}};
    }
    function backgroundOf(host) {
        function find(item) {
            if (item.color !== undefined) return item.color;
            for (const child of item.children || []) {
                const color = find(child);
                if (color !== null) return color;
            }
            return null;
        }
        return find(host.surface.contentItem);
    }
    WidgetController {
        id: controller
        entries: [{id: "example", enabled: true, width: 420, height: 580}]
        testNow: Quickshell.env("WIDGETS_IPC_TEST") === "1" ? -1 : 0
    }
    WidgetIpc { controller: controller }
    WidgetController {
        id: panels
        entries: [
            {id: "large", enabled: true, width: 420, height: 580, component: "widgets/example/Widget.qml"},
            {id: "small", enabled: true, width: 320, height: 240, component: "widgets/compact/Widget.qml", unloadOnClose: true},
            {id: "broken", enabled: true, width: 100, height: 100, component: "broken/Widget.qml"}]
        testNow: 0
    }
    WidgetHost { id: large; definition: panels.entries[0]; controller: panels }
    WidgetHost { id: small; definition: panels.entries[1]; controller: panels }
    WidgetHost { definition: panels.entries[2]; controller: panels }
    Connections {
        target: Style
        function onThemeChanged() {
            if (Quickshell.env("WIDGETS_IPC_TEST") !== "1") return;
            if (!Qt.colorEqual(backgroundOf(large), Style.theme.background)
                || !Qt.colorEqual(large.widgetContext.foreground, Style.theme.foreground)) {
                console.error("socket theme did not reach popup/content"); Qt.exit(1);
            }
            console.log("QML native theme applied: " + Style.background + "/" + Style.foreground);
            if (Style.theme.buttons) {
                if (!buttonProbe) buttonProbe=Qt.createComponent("controls/Button.qml").createObject(large.surface.contentItem,{text:"Socket probe"});
                const state=Style.theme.buttons.states.normal;
                if (!buttonProbe || !Qt.colorEqual(buttonProbe.appearance.background,state.background)
                    || !Qt.colorEqual(buttonProbe.contentItem.color,state.foreground)) {
                    console.error("socket button theme did not reach control"); Qt.exit(1); return;
                }
                console.log("QML socket button applied: " + buttonProbe.appearance.background + "/" + buttonProbe.contentItem.color);
            }
        }
    }
    Timer {
        id: gentleStart
        interval: 60
        onTriggered: {
            if (!(small.progress > 0 && small.progress < 0.3)) {
                console.error("reveal must start gently; progress=" + small.progress);
                Qt.exit(1);
                return;
            }
            const progress = small.progress;
            panels.command("toggle", "small");
            if (panels.state.widgets.small.phase !== "closing" || small.progress !== progress) Qt.exit(1);
            panels.command("toggle", "small");
            if (panels.state.widgets.small.phase !== "opening" || small.progress !== progress) Qt.exit(1);
            console.log("gentle reveal and continuous toggle reversal passed");
        }
    }
    Timer {
        property int stage: 0
        property int ticks: 0
        interval: 100; repeat: true; running: Quickshell.env("WIDGETS_IPC_TEST") !== "1"
        onTriggered: {
            function check(value, message) { if (!value) { console.error(message); Qt.exit(1); } }
            check(++ticks < 100, "QML lifecycle timed out");
            if (stage === 1 && panels.state.widgets.small.phase === "opening") return;
            if (stage === 2 && panels.state.widgets.small.phase === "closing") return;
            if (stage === 3 && panels.state.widgets.large.phase === "opening") return;
            if (stage === 4 && panels.state.widgets.large.phase === "closing") return;
            if (stage === 0) {
                const component=Qt.createComponent("controls/Button.qml");
                check(component.status===Component.Ready, "shared themed button missing: "+component.errorString());
                buttonProbe=component.createObject(small.surface.contentItem,{text:"Probe"});
                check(buttonProbe!==null,"shared button cannot instantiate");
                Style.animationsEnabled=false;
                check(Style.logicalFontSize(Qt.font({pointSize:11})) * 72 / 96 === 11,
                    "point fonts lose precision through pixelSize conversion");
                check(Style.buttonFont.pixelSize === Qt.application.font.pointSize * 96 / 72,
                    "fallback rounds the Qt application point font");
                Style.applyTheme(buttonPalette());
                check(Qt.colorEqual(buttonProbe.background.color,"#ff203040"),"button ignores native normal style");
                check(buttonProbe.implicitHeight===32,"button theme metrics not logical");
                const fractional=buttonPalette();fractional.buttons.font.pixelSize=15.5;Style.applyTheme(fractional);
                check(buttonProbe.font.pointSize===11.625,"fractional native font size rounded to integer pixels");
                buttonProbe.down=true;
                check(Qt.colorEqual(buttonProbe.background.color,"#ff607080"),"button ignores native pressed style");
                buttonProbe.enabled=false;
                check(Qt.colorEqual(buttonProbe.background.color,"#ff102030") && Qt.colorEqual(buttonProbe.contentItem.color,"#80f0f1f2"),"disabled alpha or precedence lost");
                buttonProbe.enabled=true;buttonProbe.down=false;buttonProbe.checkable=true;buttonProbe.checked=true;
                check(Qt.colorEqual(buttonProbe.background.color,"#ff8090a0"),"button ignores native checked style");
                buttonProbe.destroy();buttonProbe=null;
                check(typeof Style.applyTheme === "function", "native theme application missing");
                Style.applyTheme({background: "#80203040", foreground: "#fff0f1f2"});
                check(Qt.colorEqual(backgroundOf(large), "#80203040"), "popup uses native background including alpha");
                check(Qt.colorEqual(large.widgetContext.foreground, "#fff0f1f2"), "widget context uses native foreground");
                check(!large.loaded && !small.loaded, "components lazy until first open");
                check(panels.state.widgets.broken.available, "unopened broken component not loaded");
                panels.command("show", "small");
                check(!small.surface.visible, "surface must stay unmapped until adapter has verified runtime PID");
                panels.command("hide", "small");
                panels.dispatch({type: "ADAPTER_CONNECTED"});
                panels.command("show", "broken");
                panels.command("show", "large");
                panels.command("hide", "large");
                check(large.widgetContext.contentWidth === 388 && small.widgetContext.contentHeight === 208, "logical context sizes");
                panels.command("show", "small");
                check(small.surface.visible && small.progress === 0, "transparent preparing");
                panels.dispatch({type: "GEOMETRY", id: "small", requestId: panels.state.widgets.small.requestId, width: 160, height: 120});
                check(small.widgetContext.contentWidth === 128 && small.widgetContext.contentHeight === 88, "clamped logical context");
                panels.dispatch({type: "PLACED", id: "small", requestId: panels.state.widgets.small.requestId});
                gentleStart.restart();
            } else if (stage === 1) {
                const requestId = panels.state.widgets.small.requestId;
                Style.applyTheme({background: "#fff6f5f4", foreground: "#ff222226"});
                check(Qt.colorEqual(backgroundOf(small), "#fff6f5f4"), "open popup does not follow theme change");
                check(Qt.colorEqual(small.widgetContext.foreground, "#ff222226"), "open content foreground remains dark-theme color");
                check(panels.state.widgets.small.requestId === requestId, "theme change restarts widget lifecycle");
                check(panels.state.widgets.small.phase === "open", "animation completed: " + JSON.stringify(panels.state) + " progress=" + small.progress);
                check(large.loaded && small.loaded, "components load on first open and persist");
                Style.applyTheme(buttonPalette());
                const close=findClose(small), largeClose=findClose(large);
                check(close && largeClose,"both demo close buttons must use shared component");
                check(Qt.colorEqual(close.background.color,"#ff203040") && Qt.colorEqual(largeClose.background.color,"#ff203040"),"demo buttons do not update with native theme");
                close.forceActiveFocus(Qt.TabFocusReason);
                check(close.visualFocus && close.appearance.focusWidth===2,"keyboard focus ring missing");
                Style.applyTheme({background:"#ffeeeeee",foreground:"#ff222222"});
                check(!Style.theme.buttons && close.appearance.foreground!==undefined && close.implicitHeight>0,"legacy palette has no portable button fallback");
                check(!panels.state.widgets.broken.available, "broken isolated on first open");
                check(small.surface.width === 184 && small.surface.height === 144, "clamped fixed surface");
                check(small.scrollRequired, "clamped content remains scrollable");
                close.click();
                check(small.surface.visible && panels.state.widgets.small.phase === "closing", "closing remains mapped");
            } else if (stage === 2) {
                check(!small.surface.visible && panels.state.widgets.small.phase === "closed", "closed unmapped");
                check(!small.loaded, "unloadOnClose releases content");
                panels.command("show", "small");
                stage = 20; return;
            } else if (stage === 20) {
                check(small.loaded, "unloaded content loads again on reopen");
                panels.command("hide", "small");
                panels.animationsEnabled = false;
                panels.command("show", "large");
                panels.dispatch({type: "PLACED", id: "large", requestId: panels.state.widgets.large.requestId});
                stage = 3; return;
            } else if (stage === 3) {
                check(panels.state.widgets.large.phase === "open" && large.progress === 1, "animations disabled opens");
                findClose(large).click();
            } else {
                check(!large.surface.visible && panels.state.widgets.large.phase === "closed", "animations disabled closes");
                console.log("QML components, failure isolation, context and animation passed");
                Qt.exit(0);
            }
            stage++;
        }
    }
    Timer {
        interval: 50; running: Quickshell.env("WIDGETS_IPC_TEST") !== "1"
        onTriggered: {
            if (controller.command("show", "missing")) Qt.exit(1);
            if (controller.command("hide", "__proto__") || controller.command("hide", "constructor")) Qt.exit(1);
            if (controller.dispatch({type: "AVAILABLE", id: "__proto__", value: false})) Qt.exit(1);
            if (({}).phase !== undefined) Qt.exit(1);
            controller.dispatch({type: "ADAPTER_CONNECTED"});
            if (!controller.command("show", "example")) Qt.exit(1);
            const id = controller.state.widgets.example.requestId;
            if (!controller.dispatch({type: "PLACED", id: "example", requestId: id})) Qt.exit(1);
            if (controller.state.widgets.example.phase !== "opening") Qt.exit(1);
            console.log("QML controller/IPC smoke passed");
        }
    }
}
