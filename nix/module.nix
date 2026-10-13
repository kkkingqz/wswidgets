# Home Manager module: the Quickshell runtime as a user service, the QML,
# the manifest of the enabled widgets, the GNOME panel adapter and ws-widgets.
# Enabling the adapter (org.gnome.shell enabled-extensions) is left to the
# owner of the extension list: extensionUuid names it.
{ config, lib, pkgs, ... }:
let
  cfg = config.programs.wswidgets;
  packages = import ./packages.nix { inherit pkgs; };
  inherit (packages) runtime;
  uuid = "workstation-widgets@local";
  manifest = import ./manifest.nix {
    inherit lib;
    catalog = import ../catalog.nix;
    inherit (cfg) widgets;
    qmlRoot = ../quickshell;
  };
  manifestFile = pkgs.writeText "widget-manifest.json" (builtins.toJSON manifest);
  # GNOME Wayland only. A gamescope session (gamescope-session-plus) starts
  # graphical-session.target too, and the user manager may still hold the
  # environment of the GNOME session before it ([g]: the pattern must not
  # match its own pgrep, nor another check running at the same moment).
  sessionGuard = pkgs.writeShellScript "widgets-session-guard" ''
    case ":''${XDG_CURRENT_DESKTOP:-}:" in *:GNOME:*) ;; *) exit 1 ;; esac
    test -n "''${WAYLAND_DISPLAY:-}" || exit 1
    ! ${pkgs.procps}/bin/pgrep -u "$UID" -f '[g]amescope-session-plus' >/dev/null
  '';
in
{
  options.programs.wswidgets = {
    enable = lib.mkEnableOption "the wswidgets Quickshell runtime and GNOME panel adapter";
    widgets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "example" "compact" ];
      description = "IDs of catalog.nix to show, in panel order.";
    };
    qmlCheckout = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/home/user/Projects/wswidgets";
      description = ''
        Absolute path of a wswidgets checkout. When set, the QML is linked
        from its quickshell/ directory (edits need only `ws-widgets restart`);
        null uses the QML of the flake input.
      '';
    };
    extensionUuid = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = uuid;
      description = "UUID of the GNOME panel adapter to enable.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = cfg.qmlCheckout == null || lib.hasPrefix "/" cfg.qmlCheckout;
      message = "programs.wswidgets.qmlCheckout must be an absolute path";
    }];

    home.packages = [ packages.cli ];

    xdg.configFile."quickshell/workstation-widgets".source =
      if cfg.qmlCheckout == null then packages.qml
      else config.lib.file.mkOutOfStoreSymlink "${cfg.qmlCheckout}/quickshell";

    # force: replaces the copy an earlier installer left there.
    home.file.".local/share/gnome-shell/extensions/${uuid}" = {
      source = packages.extension;
      recursive = true;
      force = true;
    };

    xdg.dataFile."workstation/widgets/manifest.json".source = manifestFile;
    xdg.dataFile."workstation/widgets/runtime.json".text = builtins.toJSON {
      schemaVersion = 2;
      qsPath = "${runtime}/bin/qs-widgets";
      socketPath = "$XDG_RUNTIME_DIR/workstation-widgets/control.sock";
      manifestPath = "${config.xdg.dataHome}/workstation/widgets/manifest.json";
      adapter = "gnome";
    };

    systemd.user.services.workstation-widgets = {
      Unit = {
        Description = "Workstation shared widget runtime";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        StartLimitIntervalSec = 60;
        StartLimitBurst = 5;
        # Store QML: a new version restarts the runtime (it does not watch files).
        X-Restart-Triggers = lib.optional (cfg.qmlCheckout == null) "${packages.qml}";
      };
      Service = {
        # A manifest change changes the unit, so Home Manager restarts the runtime.
        Environment = [ "WIDGETS_MANIFEST=${manifestFile}" "WIDGETS_SOCKET=%t/workstation-widgets/control.sock" ];
        RuntimeDirectory = "workstation-widgets";
        RuntimeDirectoryMode = "0700";
        UMask = "0077";
        ExecCondition = sessionGuard;
        # Peer EOF is the normal liveness signal (CLI reply, adapter reload), and
        # Quickshell logs each one as a socket warning. Failures surface in state.
        ExecStart = "${runtime}/bin/qs-widgets --session -n --log-rules quickshell.io.socket.warning=false -c workstation-widgets";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
