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

  // Mirrored from CameraPanel so the bar can show recording state
  // even while the panel itself is closed.
  readonly property bool recording:
    panelLoader.item ? panelLoader.item.recording === true : false

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

  // Stop an in-progress recording without opening the panel.
  // Safe to call at any time: it only acts when a recording is running.
  function stopRecording() {
    if (panelLoader.item && root.recording)
      panelLoader.item.toggleRecording()
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

    // Panel's barTooltip already switches to "Camera · ● Recording mm:ss"
    tooltipText: panelLoader.item
      ? panelLoader.item.barTooltip
      : "Camera"

    // Stay highlighted while the panel is open or a recording is running
    active: root.opened || root.recording
    useActiveColor: root.opened || root.recording

    onPressed: function(mouseButton) {
      if (mouseButton === Qt.LeftButton)
        root.togglePanel()
      else if (mouseButton === Qt.RightButton)
        root.stopRecording()
    }

    // Blinking red recording dot (top-right of the icon)
    Rectangle {
      id: recDot

      visible: root.recording
      width: Style.space(6)
      height: width
      radius: width / 2
      color: "#ff4d4d"

      anchors.top: parent.top
      anchors.right: parent.right
      anchors.topMargin: Style.space(4)
      anchors.rightMargin: Style.space(4)

      SequentialAnimation on opacity {
        running: root.recording
        loops: Animation.Infinite

        NumberAnimation { to: 0.25; duration: 600; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
      }
    }
  }
}