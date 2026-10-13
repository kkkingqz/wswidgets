# The manifest of the enabled widgets: catalog entries by ID, panelOrder
# from the position in `widgets`.
{ lib, catalog, widgets, qmlRoot }:
let
  byId = lib.listToAttrs (map (e: lib.nameValuePair e.id e) catalog);
  catalogIds = map (e: e.id) catalog;
  unknown = lib.filter (id: !(byId ? ${id})) widgets;
  entries = lib.imap0 (i: id:
    { enabled = true; unloadOnClose = false; panelPosition = "right"; panelOrder = i; } // byId.${id}) widgets;
  safeFile = value:
    let
      parts = lib.splitString "/" value;
      walk = root: rest:
        let name = builtins.head rest;
            type = (builtins.readDir root).${name} or "missing";
        in if builtins.length rest == 1 then type == "regular"
           else type == "directory" && walk (root + "/${name}") (builtins.tail rest);
    in builtins.isString value && builtins.match "[a-zA-Z0-9_./-]+\\.qml" value != null
       && lib.all (p: p != "" && p != "." && p != "..") parts && walk qmlRoot parts;
  valid = e:
    builtins.isString e.id && builtins.match "[a-z][a-z0-9-]*" e.id != null
    && builtins.isBool e.enabled && builtins.isBool e.unloadOnClose
    && lib.all (x: builtins.isInt x && x > 0) [ e.width e.height ]
    && lib.elem e.panelPosition [ "left" "center" "right" ] && builtins.isInt e.panelOrder
    && lib.all (x: builtins.isString x && x != "") [ e.label e.iconName ]
    && safeFile e.component;
in
assert lib.assertMsg (builtins.length catalogIds == builtins.length (lib.unique catalogIds)) "duplicate widget ID in the catalog";
assert lib.assertMsg (unknown == [ ])
  "unknown widget ID: ${lib.concatStringsSep ", " unknown} (catalog: ${lib.concatStringsSep ", " catalogIds})";
assert lib.assertMsg (builtins.length widgets == builtins.length (lib.unique widgets)) "widget ID enabled twice";
assert lib.assertMsg (lib.all valid entries) "invalid widget catalog entry or unsafe/missing QML component";
{ schemaVersion = 1; widgets = entries; }
