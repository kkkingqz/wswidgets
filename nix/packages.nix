# What the module installs, built with the consumer's nixpkgs.
{ pkgs }:
{
  # Quickshell and Mesa of this nixpkgs in their own closure.
  runtime = import ./runtime.nix { inherit pkgs; };
  # Only the QML, so a change of tests or docs does not restart the runtime.
  qml = builtins.path { path = ../quickshell; name = "wswidgets-qml"; };
  extension = builtins.path { path = ../extension; name = "workstation-widgets-extension"; };
  cli = pkgs.writeShellScriptBin "ws-widgets" ''
    exec ${pkgs.python3.interpreter} ${builtins.path { path = ../lib; name = "wswidgets-lib"; }}/widgets_cli.py "$@"
  '';
}
