# wswidgets

Quickshell widget runtime with a GNOME Shell panel adapter: one user service
runs every widget, the `workstation-widgets@local` extension puts a button per
widget on the top panel and places the popup window under it.

- `quickshell/` — runtime framework (`framework/`), GNOME window adapter and
  the widgets (`widgets/<id>/Widget.qml`);
- `catalog.nix` — every widget: ID, label, icon, size, component;
- `extension/` — GNOME Shell 50 extension (panel buttons, placement, theme);
- `lib/`, `bin/ws-widgets` — CLI: start/stop/status, show/hide/toggle, check;
- `nix/` — packages, manifest builder, Home Manager module;
- `tests/` — Python and GJS unit tests, headless QML and runtime checks.

Install with the Home Manager module and enable the widgets by ID:

```nix
imports = [ inputs.wswidgets.homeManagerModules.default ];
programs.wswidgets = { enable = true; widgets = [ "example" "compact" ]; };
```

Enable the extension `config.programs.wswidgets.extensionUuid` in
`org.gnome.shell enabled-extensions`, then log out and in once.

`lib.catalog` lists every widget of a version (`nix eval --json …#lib.catalog`).

`nix flake check` runs every test. Full documentation (Russian):
[docs/ws-widgets.md](docs/ws-widgets.md); design notes in `docs/specs` and
`docs/plans`.

## License

Licensed under either of [Apache License 2.0](LICENSE-APACHE) or
[MIT license](LICENSE-MIT) at your option.
