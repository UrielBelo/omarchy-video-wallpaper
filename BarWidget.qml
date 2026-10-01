import QtQuick
import Quickshell
import qs.Ui

// KNOWN ISSUE: the click handler below does not currently fire in testing --
// see "Known issues" in the repo README. The bar icon renders and the plugin
// loads with no QML errors, but WidgetButton's onPressed never triggers.
// Left in place (rather than removed) since the manifest/path-resolution
// parts are correct and this may be a Quattro-side quirk for third-party
// bar-widgets specifically; a PR fixing the click is welcome.
BarWidget {
  id: root
  moduleName: "io.github.urielbelo.video-wallpaper"
  property var manifest: null

  readonly property string pluginDir: Quickshell.env("HOME") + "/.config/omarchy/plugins/" + (manifest ? manifest.id : "")

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "🎬"
    horizontalMargin: 7.5
    tooltipText: "Wallpaper picker"
    onPressed: function(buttonCode) {
      if (!root.bar) return
      root.bar.run(root.pluginDir + "/bin/omarchy-wallpaper-picker")
    }
  }
}
