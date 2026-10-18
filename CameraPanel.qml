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
  property bool recordAudio: false
  property string noticeText: ""
  property bool noticeIsError: false
  readonly property string snapshotDir: Quickshell.env("HOME") + "/Pictures/Camera"
  readonly property string videoDir: Quickshell.env("HOME") + "/Videos/Camera"

  // Camera state mirrored from the on-demand capture component
  property string deviceLabel: ""
  property bool cameraLoaded: false
  property int errorCode: 0
  property string errorLabel: ""
  property bool captureReady: false
  property bool frameReady: false
  property bool recording: false
  property int recordMs: 0

  readonly property bool cameraReady: root.deviceLabel !== ""
    && root.errorCode === Camera.NoError
  readonly property bool cameraFailed: root.errorCode !== Camera.NoError
  readonly property string deviceName: root.deviceLabel !== ""
    ? root.deviceLabel
    : (root.cameraLoaded ? "No camera detected" : "Camera")
  readonly property string statusText: root.noticeText !== ""
    ? root.noticeText
    : (root.recording
        ? "● Recording " + root.formatDuration(root.recordMs)
        : (root.cameraFailed
            ? (root.errorLabel || "Camera unavailable")
            : root.deviceName))
  readonly property string barTooltip: root.recording
    ? "Camera · ● Recording " + root.formatDuration(root.recordMs)
    : (root.deviceLabel !== "" ? "Camera · " + root.deviceLabel : "Camera")

  function setNotice(text, isError) {
    noticeText = text
    noticeIsError = isError === true
  }

  function open(payload) { root.controller.show() }
  function close() { root.controller.hide() }
  function toggle() { root.opened ? root.close() : root.open({}) }

  function resetCameraState() {
    root.deviceLabel = ""
    root.cameraLoaded = false
    root.errorCode = 0
    root.errorLabel = ""
    root.captureReady = false
    root.frameReady = false
    root.recording = false
    root.recordMs = 0
  }

  function two(n) { return (n < 10 ? "0" : "") + n }

  function timestamp() {
    var d = new Date()
    return String(d.getFullYear()) + two(d.getMonth() + 1) + two(d.getDate())
      + "-" + two(d.getHours()) + two(d.getMinutes()) + two(d.getSeconds())
  }

  function formatDuration(ms) {
    var s = Math.floor(ms / 1000)
    return two(Math.floor(s / 60)) + ":" + two(s % 60)
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
    root.setNotice("", false)
    preview.item.captureToFile(root.snapshotDir
      + "/camera-" + root.timestamp() + ".jpg")
  }

  function toggleRecording() {
    if (!preview.item) return
    if (root.recording) {
      preview.item.stopRecording()
      return
    }
    if (!root.cameraReady || !root.frameReady) {
      root.setNotice("Camera is still starting…", false)
      return
    }
    root.setNotice("", false)
    preview.item.startRecording(root.videoDir
      + "/camera-" + root.timestamp() + ".mp4")
  }

  Process {
    id: ensureDir
    command: ["mkdir", "-p", root.snapshotDir, root.videoDir]
  }

  onOpenedChanged: {
    if (root.opened) {
      root.setNotice("", false)
      // NOTE: no resetCameraState() here, the Loader handles it when it deactivates
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
          // stay alive while recording, even if the panel is closed
          active: root.opened || root.recording
          sourceComponent: captureComponent

          onActiveChanged: if (!active) root.resetCameraState()
        }

        // recording indicator
        Rectangle {
          visible: root.recording
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.margins: Style.spacing.sm
          width: recLabel.implicitWidth + Style.spacing.md * 2
          height: recLabel.implicitHeight + Style.spacing.xs * 2
          radius: height / 2
          color: Qt.rgba(0, 0, 0, 0.6)

          Text {
            id: recLabel
            anchors.centerIn: parent
            text: "● REC " + root.formatDuration(root.recordMs)
            color: "#ff4d4d"
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }
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
          enabled: root.cameraReady && root.captureReady
          onClicked: root.takeSnapshot()
        }

        Button {
          text: root.recording ? "Stop" : "Record"
          selected: root.recording
          focusable: true
          enabled: root.recording || (root.cameraReady && root.frameReady)
          onClicked: root.toggleRecording()
        }

        Button {
          text: root.recordAudio ? "Mic: on" : "Mic: off"
          selected: root.recordAudio
          focusable: true
          enabled: !root.recording
          onClicked: root.recordAudio = !root.recordAudio
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
        imageCapture.captureToFile(path)
      }

      function startRecording(path) {
        recorder.outputLocation = "file://" + path
        recorder.record()
      }

      function stopRecording() {
        recorder.stop()
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

        // Qt 6 VideoOutput has no `mirrored`; flip with a transform
        transform: Scale {
          origin.x: videoOutput.width / 2
          xScale: root.mirror ? -1 : 1
        }

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

      MediaRecorder {
        id: recorder
        quality: MediaRecorder.HighQuality
        mediaFormat {
          fileFormat: MediaFormat.MPEG4
        }

        onRecorderStateChanged: {
          root.recording = recorderState === MediaRecorder.RecordingState
          if (recorderState === MediaRecorder.StoppedState && recorder.actualLocation.toString() !== "")
            root.setNotice("Saved " + recorder.actualLocation.toString().replace("file://", ""), false)
        }
        onDurationChanged: root.recordMs = duration
        onErrorOccurred: function(error, errorString) {
          root.recording = false
          root.setNotice("Recording failed: " + errorString, true)
        }
      }

      AudioInput {
        id: micInput
        muted: !root.recordAudio
      }

      CaptureSession {
        id: capture
        camera: camera
        videoOutput: videoOutput
        imageCapture: imageCapture
        recorder: recorder
        audioInput: root.recordAudio ? micInput : null
      }

      Component.onCompleted: {
        root.captureReady = imageCapture.readyForCapture
        root.frameReady = videoOutput.contentRect.width > 0
          && videoOutput.contentRect.height > 0
      }
    }
  }
}