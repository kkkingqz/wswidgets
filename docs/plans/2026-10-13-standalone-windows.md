# Standalone Windows Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans inline; fresh branch review before delivery.

**Goal:** Add independently movable/resizable widget windows without changing default popups.
**Architecture:** presentation selects a host; shared content/context; model separates independent windows from the exclusive popup; GNOME activates ordinary windows without popup mutations.
**Tech Stack:** QML/Quickshell0.3, GJS/St/Meta, Unix JSON socket, Nix.
**Spec:** docs/specs/2026-10-13-standalone-windows.md

## Global Constraints
- ProtocolVersion2 and legacy manifests/snapshots remain accepted.
- Default presentation popup; one popup, any independent windows.
- Logical client sizes; no extra scale, process or periodic idle timers.
- All surfaces close on adapter EOF; explicit hideAll includes windows.
- No production standalone widget enabled; current two demos remain popups.

## Review Focus
- Closing/failing/resizing a normal window must preserve popup selection/pending intent.
- Focus/outside/overview/workspace handlers must never dismiss standalone windows.
- Native resizing and reopen must not impose initial/fixed geometry again.
- Adapter must retain normal window type/switcher/native effects and verify PID/title.
- Deferred lazy load, minimum bounds, stale resize/placement events and EOF must be isolated.

### Task 1: Manifest and lifecycle
Files: nix/manifest.nix, nix/test-manifest.nix, both manifest.mjs copies,
model.mjs, wire.mjs, WidgetIpc.qml, extension/protocol.mjs, model/manifest/protocol tests.
Interfaces: presentation popup|window; minimumWidth/minimumHeight; COMMAND hidePopups;
internal RESIZED{id,requestId,width,height}; selectedId/pendingId refer only to popup.
- [x] Write failing manifest normalization/invalid bounds and lifecycle tests for two windows+popup, popup-only dismissal, targeted close/failure, resize/reopen, adapter EOF.
- [x] Run GJS relevant suites; confirm RED, implement normal-window branch and validation; run all GJS and Nix manifest checks GREEN.

### Task 2: Host and GNOME policies
Files: WidgetHost.qml, new PopupWidgetHost.qml, WindowWidgetHost.qml, WidgetContent.qml;
extension/windowPlacement.js, windowEffects.mjs, extension.js; QML/placement/effects/socket tests; docs/ws-widgets.md/live-checklist.md.
Interfaces: WidgetHost retains surface/widgetContext/loaded/progress/scrollRequired;
WidgetContent supplies context and lazy Loader; normal host actual width/height dispatch RESIZED.
- [x] Write actual QML failing checks for independent visible surfaces, native size limits, context/resize/reopen/unload, Escape/close, coexistence and EOF.
- [x] Write native-boundary adapter tests forbidding normal-window popup mutations and effect suppression.
- [x] Implement host selection/shared content and normal native window; isolate adapter popup dismissal and activation branches.
- [x] Run full flake checks, isolated native GNOME move/resize/focus/activation probes and consumer build; fix any failure.
- [x] Update authoring docs/live checklist; obtain whole-branch review and fix findings.
- [x] Commit/local integrate and install local input without publishing or changing consumer pin; verify ws check widgets.

Execution evidence: ~/.cache/wswidgets-execution/2026-10-13/windows/.

Review/native fixes: normal preparation waits for mapping, then acknowledges once
activation is requested without requiring focus. Global decoration suppression is
removed; popup alone sets FramelessWindowHint. Native Escape RED required a
window-scoped Shortcut instead of a focus-dependent body Keys handler. Actual
native titlebar/border/caption-close/Escape/EOF probes and full checks are GREEN.

Delivery2026-10-14:100c702+7d682aa fast-forwarded into local main. Merged-tree
flake check passes; installed through ws switch with local input/no-write-lock-file.
ws check widgets:6PASS/0WARN/0FAIL; service active,NRestarts0; installed QML/JS
matches source. Consumer lock hash unchanged, no publication. New GNOME login
is required to load the new extension module.
