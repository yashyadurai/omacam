import QtQuick
import qs.Ui
import qs.Commons

BarWidget {
  id: root

  moduleName: "camera"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // The bar owns the panel identity. Panel routing expects
  // open/close/opened on the bar-widget root.
  readonly property bool opened:
    panelLoader.item ? panelLoader.item.opened === true : false

  function open() {
    if (panelLoader.item)
      panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item)
      panelLoader.item.close()
  }

  function togglePanel() {
    if (panelLoader.item)
      panelLoader.item.toggle()
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target)
      return

    if ("bar" in target)
      target.bar = root.bar

    if ("settings" in target)
      target.settings = root.settings

    if ("anchorItem" in target)
      target.anchorItem = button

    if ("hostWidget" in target)
      target.hostWidget = root
  }

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader

    active: true
    visible: false
    source: Qt.resolvedUrl("CameraPanel.qml")

    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  BarIconButton {
    id: button

    anchors.fill: parent
    bar: root.bar

    // Nerd Font camera glyph (U+F0100), matching the shell's icon family.
    text: "\uDB80\uDD00"
    slotSize: Style.bar.iconSlot

    tooltipText: panelLoader.item
      ? panelLoader.item.barTooltip
      : "Camera"

    active: root.opened
    useActiveColor: root.opened

    onPressed: function(mouseButton) {
      if (mouseButton === Qt.LeftButton)
        root.togglePanel()
    }
  }
}
