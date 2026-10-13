{
  description = "wswidgets: Quickshell widget runtime with a GNOME panel adapter (MIT OR Apache-2.0)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (nixpkgs) lib;
      packages = import ./nix/packages.nix { inherit pkgs; };
      catalog = import ./catalog.nix;
      # The whole catalog in its order: what the checks run against.
      manifest = import ./nix/manifest.nix {
        inherit lib catalog;
        widgets = map (e: e.id) catalog;
        qmlRoot = ./quickshell;
      };
      manifestFile = pkgs.writeText "widgets-manifest.json" (builtins.toJSON manifest);
      testEnv = ''
        export HOME="$TMPDIR/home" XDG_RUNTIME_DIR="$TMPDIR/runtime"
        mkdir -p "$HOME" "$XDG_RUNTIME_DIR"
        chmod 700 "$XDG_RUNTIME_DIR"
      '';
    in {
      homeManagerModules.default = import ./nix/module.nix;
      # Every widget of this version (ID, label, icon, size, component), for
      # tools that choose the enabled ones: nix eval --json …#lib.catalog.
      lib.catalog = catalog;

      packages.${system} = {
        default = packages.cli;
        inherit (packages) runtime cli;
      };

      checks.${system} = {
        manifest = assert import ./nix/test-manifest.nix { inherit lib; }; manifestFile;
        qml = pkgs.runCommand "wswidgets-qml" { nativeBuildInputs = [ pkgs.python3 ]; } ''
          ${testEnv}
          python ${self}/tests/check-qml.py ${packages.runtime}/bin/qs-widgets
          touch "$out"
        '';
        # The adapter keeps its own copy of the manifest validator.
        tests = assert builtins.readFile ./quickshell/framework/manifest.mjs == builtins.readFile ./extension/lib/manifest.mjs;
          pkgs.runCommand "wswidgets-tests" { nativeBuildInputs = [ pkgs.python3 pkgs.gjs ]; } ''
            cp -r ${self} source
            chmod -R u+w source
            cd source
            patchShebangs bin/ws-widgets
            python -m unittest discover -s tests -p 'test_*.py'
            gjs -m tests/run-tests.js
            touch "$out"
          '';
        runtime = pkgs.runCommand "wswidgets-runtime-integration" { nativeBuildInputs = [ pkgs.python3 pkgs.gjs ]; } ''
          ${testEnv}
          python ${self}/tests/check-runtime.py --runtime ${packages.runtime}/bin/qs-widgets --manifest ${manifestFile}
          touch "$out"
        '';
        cli = pkgs.runCommand "wswidgets-cli" { } ''
          ${packages.cli}/bin/ws-widgets --help | grep -q 'Usage: ws-widgets'
          touch "$out"
        '';
      };
    };
}
