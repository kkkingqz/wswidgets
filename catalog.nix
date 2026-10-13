# Every widget this project ships, one definition per widget; shared by
# Quickshell and the GNOME adapter. A host enables some of them by ID in
# panel order (programs.wswidgets.widgets); unknown IDs fail the build.
# unloadOnClose defaults to false; set true for content that should release memory.
[
  { id = "example"; label = "Workstation widgets"; iconName = "view-grid-symbolic";
    component = "widgets/example/Widget.qml"; width = 420; height = 580; }
  { id = "compact"; label = "Компактный виджет"; iconName = "starred-symbolic";
    component = "widgets/compact/Widget.qml"; width = 320; height = 240; }
]
