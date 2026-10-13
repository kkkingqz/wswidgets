{ lib }:
let
  entry = { id = "example"; label = "Example"; iconName = "view-grid-symbolic";
    component = "shell.qml"; width = 420; height = 580; };
  make = catalog: widgets: import ./manifest.nix { inherit lib catalog widgets; qmlRoot = ../tests/probe; };
  accepts = catalog: widgets: (builtins.tryEval (builtins.deepSeq (make catalog widgets) true)).success;
  other = entry // { id = "other"; };
  orders = map (e: e.panelOrder) (make [ entry other ] [ "other" "example" ]).widgets;
in
assert accepts [ entry ] [ "example" ];
assert (builtins.head (make [ entry ] [ "example" ]).widgets).presentation == "popup";
assert accepts [ (entry // { presentation = "window"; minimumWidth = 240; minimumHeight = 160; }) ] [ "example" ];
assert !(accepts [ (entry // { presentation = "panel"; }) ] [ "example" ]);
assert !(accepts [ (entry // { minimumWidth = 0; }) ] [ "example" ]);
assert !(accepts [ (entry // { minimumHeight = 581; }) ] [ "example" ]);
assert accepts [ entry ] [ ];
assert orders == [ 0 1 ];
assert (builtins.head (make [ entry other ] [ "other" "example" ]).widgets).id == "other";
assert accepts [ (entry // { unloadOnClose = true; }) ] [ "example" ];
assert !(accepts [ (entry // { unloadOnClose = "yes"; }) ] [ "example" ]);
assert !(accepts [ entry entry ] [ "example" ]);
assert !(accepts [ entry ] [ "example" "example" ]);
assert !(accepts [ entry ] [ "missing" ]);
assert !(accepts [ (entry // { width = 0; }) ] [ "example" ]);
assert !(accepts [ (entry // { width = 1.5; }) ] [ "example" ]);
assert !(accepts [ (entry // { panelPosition = "outside"; }) ] [ "example" ]);
assert !(accepts [ (entry // { component = "../shell.qml"; }) ] [ "example" ]);
assert !(accepts [ (entry // { component = "missing.qml"; }) ] [ "example" ]);
true
