# Live evidence — 2026-10-03

Standalone windows infrastructure — implementation started 2026-10-13:

- Existing production catalog still contains the same two popup demos. Extra
  `presentation=window` entries were enabled only in an isolated test manifest.
- Real QML hosts support two independent normal windows alongside a popup,
  resize-driven context, minimum/unbounded maximum size, retained size across
  reopen, unloadOnClose and adapter EOF. Popup composition/animation and socket
  regression checks remain passing.
- Owned headless GNOME50.1 Wayland1280×800 at scale1: both windows open together
  with NORMAL type, task-list inclusion, native effects and no above flag.
  Virtual-pointer titlebar drag moves a window by60×40; bottom/right border drags
  resize the actual logical client area400×300→460×340. These are input gestures,
  separate from a programmatic compositor geometry probe.
- Standard Qt Wayland decorations are enabled; only popup backing windows get
  FramelessWindowHint. A400×300 client has402×340 native frame in this environment.
  Mutter client-content rect also includes Qt client decorations, so it must not
  be used as a measurement of the QML content. Qt decorations can differ from GTK.
- Caption close affects only its window; reopening retains560×420 client size
  after a separate compositor resize. Escape closes the focused normal window
  through a window-scoped Shortcut, including focus inside ScrollView.
- Normal windows survive focus transfer to another application and overview.
  Both popup demos open alongside them and close through Tab/Space without
  closing the independent windows. Theme/button/font updates still apply live.
- Extension disable closes all surfaces via EOF; re-enable reconnects with all
  closed. Runtime restart also reconnects with all closed. Idle10s after restart:
  runtime0.00CPU seconds, no theme updates. This is an isolated-session sample,
  not the original60s production resource acceptance test.
- Native preparation waits for a mapped actor, then requests activation once;
  it does not require focus. Regressions cover unmapped actors and overlapping
  asynchronous normal activations. Popup activation still waits for native focus.
- Fresh branch review findings (focus race/global decoration suppression) are
  fixed. Full flake checks pass80GJS tests, Python, manifest, QML and runtime
  integration; consumer Home Manager build passes. Final installation evidence
  is recorded below after delivery.
- Host scale1.5, additional monitors, workspace/lock changes and visual agreement
  of Qt caption decoration with GTK remain outside this isolated gesture probe.
  No forced logout, production Shell evaluation or screenshot access was used.

Probe and RED/GREEN logs: ~/.cache/wswidgets-execution/2026-10-13/windows/.

Historical sections below before «Socket rewrite — 2026-10-04» describe protocol 1 (`qs ipc`
and the adapter lease). Protocol 2 replaced the lease with socket ownership:
adapter EOF closes widgets immediately; `adapter.connected` replaces `ready`.

Environment: Ubuntu GNOME Shell 50.1, Wayland; eDP-1 native 3072×1920,
logical 2048×1280, scale 1.5. Scoped Quickshell 0.3.0 / Qt 6.11.2 / Mesa 26.1.8.

Verified:

- Runtime probe: Qt DPR 1.5, transparent Wayland window, 420×580 logical.
- Production manifest loads both components; real GJS client receives
  stateChanged and snapshot, obtains/renews lease and addresses both IDs.
- Forced listener loss during opening reconnects to the same runtime instance
  and request; status remains authoritative. No stale request is restored.
- Manual placement acknowledgement starts animation, hide waits for animation.
- Real compositor frames including gutters: example 444×604, compact 344×264.
  Observed positions (802,319) and (852,489) are compositor default placements
  in the temporary test; anchoring under a panel button has **not** been verified.
- After the lazy-loading changes, both actual Qt surfaces again report mapped,
  visible, expected dimensions and DPR 1.5 through a test-only inspector.
  Repeating compositor frame inspection was unavailable: the existing
  WindowControl D-Bus object no longer exists. This is reported explicitly.
- After destroying the real GJS client, runtime unmaps the open window after
  lease expiry. All temporary runtime/client processes are terminated by tests.
- Headless clamp: compact panel 160×120, fixed surface 184×144, context 128×88,
  overflowing content remains scrollable. Broken QML is isolated.
  Contents load on first open, remain instantiated after close; disabled
  animations finish correctly. Pure button policy reports component errors.
- Deployment: current `main` history merged into `wsconfig`; primary checkout
  switched to `wsconfig`, with existing staged/unstaged files and untracked
  user document preserved byte for byte. No merge into `main` was performed.
- After synchronization: all 122 Python tests and 37 GJS tests pass; Nix
  widgets-manifest/qml/tests/runtime, both Home Manager hosts and man build.
- `ws switch` and `ws apply extensions` completed. Production QML link resolves
  to `~/wsconfig/widgets/quickshell`; runtime/manifest and CLI delivered.
  Managed service is enabled and active; restart creates a new runtime PID,
  IPC PID agrees with systemd, both widget IDs start closed, NRestarts is zero.
- Production owner check: three passes, two warnings, zero failures. Warnings
  are the unloaded GNOME adapter and absent lease; native window checks remain
  pending. Shell EnableExtension returns false for the new UUID;
  ReloadExtension returns UnknownMethod in the running GNOME 50.1.
- Managed runtime without adapter: valid `show` enters preparing, never enters
  opening/open, then closes with placement timeout after two seconds. Unknown
  ID is rejected; neither command creates another runtime process.

Review fix pass, verified separately on the same date:

- 46 GJS cases pass, including inherited ID rejection, cancellation during
  preparing, masked-area pointer policy and scoped Shell effect suppression.
  The QML/typed IPC checks also reject prototype keys in the actual Qt engine.
- The Wayland smoke confirms that surfaces remain unmapped before adapter
  readiness, then map with the expected dimensions and DPR 1.5. Compositor
  inspection is available again: example frame (802,319,444,604), compact
  (852,489,344,264). These are temporary test placements, not button anchoring.
- All 122 Python tests pass (701.694s). Nix widgets-manifest/qml/tests/runtime,
  both Home Manager hosts and man pass.
- Native effect injection and reactive picking were checked against Shell and
  Mutter 50.1 sources. Their integrated GUI behavior remains pending below.

Subsequent native-session evidence during delivery:

- After the user returned, the new GNOME session already had the extension
  ACTIVE. The managed runtime PID is 3890; adapter lease is ready, NRestarts=0.
- Both production IDs complete the real GNOME placement handshake and remain
  open; the adapter acknowledges only after verifying the compositor frame.
  Panel sizes are 420×580 and 320×240. Explicit hide completes, and restoring
  focus to the previous application closes compact through the native adapter.
- WindowControl lists NORMAL windows only; widgets disappear from that list
  after the adapter changes their native type. It cannot inspect their final
  frame/focus properties. This is not evidence for every Dock/Alt-Tab behavior.
- Live Qt IPC rejects __proto__ and constructor. Production check now reports
  five passes, zero warnings and zero failures; both widgets are left closed.
- Screenshot D-Bus denies access. No screenshot or visual animation/button
  verdict was obtained, and no unsafe Shell evaluation was enabled.
- Fixes are committed on wsconfig (c0498c7), rebased onto the existing 36e7773
  user commit. main remains at 36e7773; original user file hashes are preserved.
  ws switch and extension-owner delivery succeed; installed sources match.

Popup animation and repeat-click update — 2026-10-04:

- Commit ad62245 on wsconfig changes the transition to 300ms InOutCubic.
  The QML test first failed with the old reveal at progress 0.704 after 60ms;
  the new transition passes the gentle-start and continuous-reversal checks.
- The captured-event routing reproduced the second-click regression with a
  null event source: outside dismissal ran before toggle and reopened the
  panel. Panel ownership now uses the same reactive pick as the input mask.
  The regression test drives both capture and toggle through the real reducer.
- All 48 GJS cases, QML/typed IPC, seven Nix checks and the Wayland smoke pass.
  Surface sizes remain 444×604 and 344×264, DPR 1.5.
- All 122 Python cases at ad62245 pass in four isolated processes (140.006s).
  Persistent worker logs and the aggregate report are under
  ~/.cache/wsconfig-execution/widget-toggle-tests/. This excludes concurrent
  uncommitted changes belonging to other tasks in the primary checkout.
- ws switch, extension-owner delivery and installed-source verification pass.
  Runtime PID 120887 is active, NRestarts=0. Both production IDs open and close
  with IPC toggle; both are left closed. The owner check reports five passes,
  zero warnings and zero failures.
- The running Shell PID remains 3511, which predates this JS update. The
  animation is active in the restarted runtime; the panel-pointer correction
  still requires a normal logout/login to load the new extension module.
  A physical repeat-click verdict is therefore still pending that new session.

Remaining native GUI matrix:

- Both buttons; anchoring gap, focus, no center flash, no decorations and no
  duplicate compositor animation; actual panel coverage at scale 1.5.
- Esc, own-button rapid toggle, external Shell/client clicks, focus/transients;
  invisible parts and gutter pass pointer input through.
- Overview, workspace, lock/unlock, disable/re-enable, runtime restart;
  no stale windows, Shell signals, timers or subscriptions.
- Ubuntu Dock, Alt-Tab and Tiling Assistant exclusion; monitor/workarea changes.
- Additional scales and a second monitor: unavailable in this run; not passed.

Earlier installation evidence predates the new session; the extension is now
ACTIVE. The remaining matrix needs direct GUI observation and input. This agent
did not restart the session or log the user out.

Socket rewrite — 2026-10-04:

- User confirmed previous animation and physical repeat-click fixes work.
- New isolated socket runtime: no adapter rejects opening; takeover preserves
  the active request; old EOF cannot affect the new adapter; current EOF closes
  immediately. CLI role cannot issue placement commands. Partial Cyrillic
  UTF-8 survives socket fragmentation. Placement deadline is single-shot.
- Production QML with real rewritten Gio transport on Wayland:444×604 and
  344×264 actual Qt surfaces, DPR1.5. Runtime SIGKILL/restart reconnects to a
  new instance with both widgets closed. No test IpcHandler/qs ipc is used.
- unloadOnClose defaultfalse retains content; true unloads/reloads correctly.
- Idle60.01s: runtime0.00CPU seconds/0.05 context switches per second; standalone
  adapter0.00CPU seconds/0.117 context switches per second. Normal GLib main
  loop, production QML without test polling. This is an isolated pair, not a
  claim about the still-loaded old native extension.
- Native activation and GUI matrix require a normal login after delivery.
