# DE-themed buttons

Approved scope: replace the close buttons in example and compact with one
reusable QML control. Its appearance comes from the DE adapter; behavior stays
Qt Quick Controls. GNOME uses the existing Shell theme connection because it
already supplies popup colors. Other adapters can supply the same neutral data.

Use controls/Button.qml derived from QtQuick.Controls.Basic.Button. Keep text,
icon, Action, checkable, keyboard activation and accessible semantics. A shared
Style singleton supplies button appearance; widget code does not know the DE.

Extend setTheme with an optional buttons object: metrics (radius, padding,
minimumHeight, transitionMs), font (family, pixelSize, weight, italic), and states.
States use checked/pressed/hover/focus combinations, plus disabled. Each has
background, foreground, borderColor, borderWidth, focusColor and focusWidth.
Colors are ARGB strings; dimensions are logical pixels, finite and bounded.
Legacy background/foreground-only messages remain valid and use the Qt fallback.

GNOME computes StThemeNodes for .button in the actual popup theme ancestry and
extracts each pseudo-class combination on connection, theme/style/scale changes.
Cache and send one complete snapshot, not messages for pointer changes. Normalize
St physical actor units by the Shell theme scale; Qt scales logical values once.
Use an inset focus ring from the native shadow or outline. Complex custom CSS
images/gradients are outside this first control. Failed extraction must not break
the adapter connection; retain useful popup colors with the Qt button fallback.

Without a button theme use active/disabled SystemPalette, Qt application font and
simple logical metrics. Theme transitions respect the animation setting. No new
processes or periodic timers. Do not implement additional DE window adapters here.

Verify malformed data, state combinations/focus, logical metrics, fallback,
live theme replacement and actual close actions in both widgets. Verify real
GNOME extraction in an isolated session before production delivery.
