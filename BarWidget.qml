import QtQuick
import Quickshell
import qs.Ui

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
