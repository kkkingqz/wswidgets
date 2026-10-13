# DE-themed Buttons Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans inline. Steps use checkbox syntax.

**Goal:** Add a reusable button whose theme comes from the DE adapter and use it in both demos.

**Architecture:** Neutral button theme data extends the existing setTheme message.
GNOME reads native button states; Style normalizes adapter/fallback appearance;
controls/Button.qml keeps Qt control behavior.

**Tech Stack:** QML, Qt Quick Controls Basic, GJS/St/Pango, existing Unix socket, Nix.

**Spec:** docs/specs/2026-10-13-de-buttons.md

## Global Constraints

- Existing protocolVersion 2 and background/foreground-only theme messages remain valid.
- No new processes, periodic timers, external UI dependencies or DE-specific code in controls.
- All transmitted dimensions are logical pixels; finite/bounded data only.
- Keep both widget close actions, Qt button keyboard/Action/checkable semantics.

## Review Focus

- Focus combined with hover/pressed/checked must not disappear.
- Transparent colors and disabled colors must preserve alpha.
- GNOME extraction errors must not cause adapter reconnect loops.
- Scale and font units must not apply system scale twice.
- QML fallback must work without a GNOME/theme message.

### Task 1: Theme contract and native extraction

Files: framework/theme.mjs, extension/lib/theme.mjs (identical contract),
extension/lib/buttonTheme.js, menuTheme.js, framework/wire.mjs, tests/test-theme.js, flake.nix.

Interface: buttonStateKey(enabled, hovered, down, checked, focus); validateTheme(value).
buttons contains metrics/font and a state table with disabled plus all 16 combinations.

- [x] Write tests for state precedence, full/legacy payload validation, invalid dimensions/colors/missing states, native unit conversion and extraction error recovery.
- [x] Run gjs -m tests/run-tests.js theme; confirm failures for missing theme functionality.
- [x] Implement validation, GNOME extraction and optional payload; preserve coalescing, reconnect and alpha.
- [x] Run full GJS suite and confirm green.

### Task 2: Shared QML control and demos

Files: controls/Button.qml, framework/Style.qml, WidgetHost.qml, both demo widgets,
tests/qml/shell.qml, tests/check-qml.py, docs/ws-widgets.md.

Interface: Ui.Button with standard Qt button properties; Style.buttonAppearance(...),
buttonMetrics/buttonFont and animationsEnabled from WidgetIpc.

- [x] Add real QML assertions for native state appearance, combined focus, fallback,
  live theme replacement, sizing and closing both demos through their actual controls.
- [x] Run check-qml.py and confirm missing control/theme behavior fails.
- [x] Implement component, bindings, fallback and demo imports; preserve icon/text behavior.
- [x] Run nix flake check --print-build-logs and isolated native GNOME theme validation.
- [x] Update usage documentation, obtain fresh whole-branch review, fix actionable findings.
- [x] Commit and deliver the tested local input without changing the pinned revision or publishing.

Progress evidence is kept in ~/.cache/wswidgets-execution/2026-10-13/buttons/.
