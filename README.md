# omacam

A bar-widget plugin for **Omarchy** that adds a laptop/Webcam camera preview to your top bar. Click the camera icon to open a popup with a **live preview**, a **mirror toggle**, and one-click **snapshots** to `~/Pictures/Camera`.

Built on QtMultimedia (Qt 6.9+) via the in-process Quickshell shell.

## Features

* Live camera preview in a bar-anchored popup panel (16:9).
* **Mirror** toggle (on by default, so the preview reads like a phone front-camera). Can be defaulted off in config.
* **Snapshot** to `~/Pictures/Camera/camera-YYYYMMDD-HHMMSS.jpg`.
* Human-readable status: shows the connected device name, and a clear **"No camera detected"** / error banner if the hardware is missing or busy.
* Device is only held while the panel is open — the V4L2 node (`/dev/videoN`) is released when the panel closes, so the camera LED and file descriptor aren't grabbed at idle.
* Keyboard-friendly: `Esc` closes the panel.

## Requirements

* Omarchy shell (Quickshell-based), any recent build.
* `QtMultimedia` QML import available to the shell:

  * `qt6-multimedia` (Arch: `qt6-multimedia`)
  * `qt6-multimedia-ffmpeg` (Arch) — required for video sinks (`VideoOutput`) and `MediaRecorder`-based functions on Linux.
* A V4L2 camera (built-in laptop webcam or any `v4l2` device).
* Write access to `~/Pictures/Camera` (created automatically on open).

## Installation

Clone the repository into your Omarchy plugins directory:

```sh
git clone https://github.com/yashyadurai/omacam.git \
  ~/.config/omarchy/plugins/omacam.plugin
```

Validate the plugin:

```sh
omarchy plugin validate ~/.config/omarchy/plugins/omacam.plugin
```

Enable the plugin in the bar's `right` section:

```sh
omarchy plugin enable omacam.plugin right
```

Restart the Omarchy shell:

```sh
omarchy restart shell
```

You should now see a camera icon (`󰀀`) in the bar. Click it to open the live camera preview.

## Uninstallation

Disable the plugin:

```bash
omarchy plugin disable omacam.plugin
```

Remove the plugin from your Omarchy plugins directory:

```bash
rm -rf ~/.config/omarchy/plugins/omacam.plugin
```

Restart the Omarchy shell:

```bash
omarchy restart shell
```

If you also want to remove snapshots created by OmaCam:

```bash
rm -rf ~/Pictures/Camera
```
> **Note:** The last command only removes photos created in `~/Pictures/Camera`. Skip it if you want to keep your snapshots.

## Usage

* **Click the camera icon** to toggle the preview panel.
* **Snapshot** saves a JPEG to `~/Pictures/Camera/`.
* **Mirror** flips the preview horizontally.

### IPC

The panel is controllable from the command line or keybinds through Omarchy's IPC:

```sh
omarchy-shell camera open
omarchy-shell camera close
omarchy-shell camera toggle
```

Example Hyprland keybind:

```ini
bind = SUPER, C, exec, omarchy-shell camera toggle
```

## Configuration

Persist per-plugin settings in:

```text
~/.config/omarchy/shell.json
```

Example:

```jsonc
{
  "id": "omacam.plugin",
  "mirror": false
}
```

`mirror` can also be changed directly from the panel. The setting is persisted by Quickshell.

## Files

```text
CameraPanel.qml  — the popup panel: preview, mirror, snapshot, status
Widget.qml       — the bar icon button that opens/closes the panel
manifest.json    — plugin manifest and bar-widget entry point
```

## Development

Omarchy hot-reloads local plugins on save. Edit a `.qml` file and the plugin should reload automatically.

You can force a plugin rescan with:

```sh
omarchy-shell shell rescanPlugins
```

Validate the plugin at any time with:

```sh
omarchy plugin validate ~/.config/omarchy/plugins/omacam.plugin
```

## Compatibility / Notes

* Requires Qt 6.9+ for the `VideoOutput` / `CaptureSession` API used here.
* On some compositors/hardware, the preview may need a moment to produce the first frame; the panel shows **"Starting camera…"** until then.
* Some webcams may show a generic device name such as **"MKV/ACER HD Camera"**. This is simply the device's V4L2 description.
* The plugin uses the first available camera.
* The camera is only active while the preview panel is open.
