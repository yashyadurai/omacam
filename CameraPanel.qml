import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

Panel {
  id: root

  moduleName: "camera"
  ipcTarget: "camera"

  property var anchorItem: null
  property var hostWidget: null
  property bool mirror: setting("mirror", true)
  property string noticeText: ""
  property bool noticeIsError: false
  readonly property string snapshotDir: Quickshell.env("HOME") + "/Pictures/Camera"

  // Camera state is mirrored here from inside the on-demand capture
  // component so the panel chrome can render without keeping a Camera
  // object (and therefore the V4L2 device) alive while closed.
  property string deviceLabel: ""
  property bool cameraLoaded: false
  property int errorCode: 0
  property string errorLabel: ""
  property bool captureReady: false
  property bool frameReady: false

  readonly property bool cameraReady: root.deviceLabel !== ""
    && root.errorCode === Camera.NoError
  readonly property bool cameraFailed: root.errorCode !== Camera.NoError
  readonly property string deviceName: root.deviceLabel !== ""
    ? root.deviceLabel
    : (root.cameraLoaded ? "No camera detected" : "Camera")
  readonly property string statusText: root.noticeText !== ""
    ? root.noticeText
    : (root.cameraFailed
        ? (root.errorLabel || "Camera unavailable")
        : root.deviceName)
  readonly property string barTooltip: root.deviceLabel !== ""
    ? "Camera · " + root.deviceLabel
    : "Camera"

  function setNotice(text, isError) {
    noticeText = text
    noticeIsError = isError === true
  }

  function open(payload) {
    root.controller.show()
  }

  function close() {
    root.controller.hide()
  }

  function toggle() {
    root.opened ? root.close() : root.open({})
  }

  function resetCameraState() {
    root.deviceLabel = ""
    root.cameraLoaded = false
    root.errorCode = 0
    root.errorLabel = ""
    root.captureReady = false
    root.frameReady = false
  }

  function timestamp() {
    var d = new Date()
    function two(n) { return (n < 10 ? "0" : "") + n }
    return String(d.getFullYear()) + two(d.getMonth() + 1) + two(d.getDate())
      + "-" + two(d.getHours()) + two(d.getMinutes()) + two(d.getSeconds())
  }

  function takeSnapshot() {
    if (!root.cameraReady) {
      root.setNotice("No camera is available", true)
      return
    }
    if (!root.captureReady || !preview.item) {
      root.setNotice("Camera is still starting…", false)
      return
    }
    preview.item.captureToFile(root.snapshotDir
      + "/camera-" + root.timestamp() + ".jpg")
  }

  Process {
    id: ensureDir
    command: ["mkdir", "-p", root.snapshotDir]
  }

  onOpenedChanged: {
    if (root.opened) {
      root.setNotice("", false)
      root.resetCameraState()
      if (!ensureDir.running) ensureDir.running = true
    }
  }

  KeyboardPanel {
    id: popup
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    centerOnBar: false
    padding: Style.spacing.panelPadding
    contentWidth: popup.fittedContentWidth(Style.space(440), Style.space(560))
    contentHeight: popup.fittedContentHeight(column.implicitHeight, Style.space(560))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
    }

    Column {
      id: column
      anchors.fill: parent
      spacing: Style.spacing.md

      Column {
        id: headerCopy
        width: parent.width
        spacing: Style.spacing.xxs

        Text {
          text: "Camera"
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.title
          font.bold: true
        }

        Text {
          width: parent.width
          text: root.deviceName
          color: Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.68)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }
      }

      Rectangle {
        id: previewFrame
        width: parent.width
        height: Math.round(width * 9 / 16)
        color: Qt.rgba(0, 0, 0, 0.45)
        radius: Style.cornerRadius
        clip: true

        Loader {
          id: preview
          anchors.fill: parent
          active: root.opened
          sourceComponent: captureComponent

          onActiveChanged: if (!active) root.resetCameraState()
        }

        Text {
          anchors.centerIn: parent
          width: parent.width - Style.spacing.lg * 2
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.WordWrap
          visible: !root.opened || root.cameraFailed || (root.opened && !root.frameReady)
          text: root.cameraFailed
            ? (root.errorLabel || "Camera unavailable")
            : (!root.opened ? "Camera is off" : "Starting camera…")
          color: Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.6)
          font.family: Style.font.family
          font.pixelSize: Style.font.body
        }
      }

      Row {
        width: parent.width
        spacing: Style.spacing.sm

        Button {
          text: root.mirror ? "Mirror: on" : "Mirror: off"
          selected: root.mirror
          focusable: true
          onClicked: root.mirror = !root.mirror
        }

        Button {
          text: "Snapshot"
          focusable: true
          onClicked: root.takeSnapshot()
        }
      }

      Text {
        width: parent.width
        text: root.statusText
        color: root.noticeIsError || root.cameraFailed
          ? Color.urgent
          : Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.62)
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
      }
    }
  }

  Component {
    id: captureComponent

    Item {
      id: captureRoot

      function captureToFile(path) {
        return imageCapture.captureToFile(path)
      }

      Camera {
        id: camera
        active: true

        onCameraDeviceChanged: root.deviceLabel = camera.cameraDevice
          ? camera.cameraDevice.description
          : ""
        onErrorChanged: {
          root.cameraLoaded = true
          root.errorCode = camera.error
          root.errorLabel = camera.errorString
        }
        Component.onCompleted: {
          root.deviceLabel = camera.cameraDevice ? camera.cameraDevice.description : ""
          root.cameraLoaded = true
          root.errorCode = camera.error
          root.errorLabel = camera.errorString
        }
      }

      VideoOutput {
        id: videoOutput
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        mirrored: root.mirror

        onContentRectChanged: root.frameReady =
          contentRect.width > 0 && contentRect.height > 0
      }

      ImageCapture {
        id: imageCapture

        onReadyForCaptureChanged: root.captureReady = readyForCapture
        onImageSaved: function(id, fileName) {
          root.setNotice("Saved " + fileName, false)
        }
        onErrorOccurred: function(id, error, errorString) {
          root.setNotice("Snapshot failed: " + errorString, true)
        }
      }

      CaptureSession {
        id: capture
        camera: camera
        videoOutput: videoOutput
        imageCapture: imageCapture
      }
    }
  }
}
