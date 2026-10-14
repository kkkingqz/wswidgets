# Standalone widget windows

User-approved intent: infrastructure for widgets with independent, movable,
resizable windows. Preserve existing popup behavior and one runtime/socket.

Catalog entries accept presentation="popup" (default) or "window". width/height
are initial logical client dimensions; minimumWidth/minimumHeight default to
min(160,width)/min(120,height), must be positive integers no greater than initial
sizes. Existing manifests remain valid. No new production widget is enabled.

One popup remains exclusive (selectedId/pendingId). Window entries have independent
lifecycle states, may coexist with each other and a popup. Both require an adapter
connection to open and close on adapter EOF. Explicit hideAll closes all entries;
adapter hidePopups only dismisses popup entries. Normal windows survive external
click, focus loss, overview/workspace/lock changes. Standard close and explicit
hide/toggle close a window immediately through its own state, without clearing
popup selection or pending intent.

Window opening still uses the bounded preparation handshake: GNOME identifies
its verified PID/title, waits for its mapped native actor and requests activation
once; current focus is not required to acknowledge an ordinary window. It does
not move/resize it, change
its native type, hide it from switchers, make it above, or suppress native effects.
The compositor chooses position. Popups retain their verified placement/activation.

A DE-neutral WindowWidgetHost uses an ordinary FloatingWindow with standard Qt/window-system frame,
move/resize, minimumSize, unbounded normal maximum, shared content/theme/font/scroll.
Native client size drives context dimensions and an internal RESIZED event; changed
sizes persist in memory across close/reopen, reset on runtime restart. Resize events
never move the window or restart opening. Popup host retains fixed sizing/animation.
Shared WidgetContent owns lazy loading, unloadOnClose, failure isolation and context;
WidgetHost selects the presentation without creating both windows. No periodic idle
polling, extra process, new desktop adapter, permanent position storage, or arbitrary
placement command is introduced.

On GNOME Wayland, Qt supplies client decorations; they may differ from GTK.
The launcher must allow decorations, and only popup backing QQuickWindows receive
FramelessWindowHint before mapping. No global decoration suppression is retained.

Acceptance: manifest and lifecycle regression tests; actual QML hosts for two normal
windows plus popup; native GNOME placement/activation, moving/resizing via compositor,
normal window type/task-list inclusion, persistent focus behavior, close/reopen,
EOF and existing popup regressions; full flake and consumer build, ws check clean.
