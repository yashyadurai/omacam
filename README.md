# omacam

A bar-widget plugin for **Omarchy** that adds a laptop/Webcam camera preview to
your top bar. Click the camera icon to open a popup with a **live preview**,
a **mirror toggle**, and one-click **snapshots** to `~/Pictures/Camera`.

Built on QtMultimedia (Qt 6.9+) via the in-process Quickshell shell.

## Features

- Live camera preview in a bar-anchored popup panel (16:9).
- **Mirror** toggle (on by default, so the preview reads like a phone
  front-camera). Can be defaulted off in config.
- **Snapshot** to `~/Pictures/Camera/camera-YYYYMMDD-HHMMSS.jpg` (Snap "JPG",
  only the specified path is saved).
- Human-readable status: shows the connected device name, and a clear
  "No camera detected" / error banner if the hardware is missing or busy.
- Device is only held while the panel is open — the V4L2 node (`/dev/videoN`)
  is released when the panel closes, so the camera LED and the file
  descriptor aren't grabbed at idle (privacy-friendly).
- Keyboard-friendly: `Esc` closes the panel (uses the standard `KeyboardPanel`
  key-catcher).

## Requirements

- Omarchy shell (Quickshell-based), any recent build.
- `QtMultimedia` QML import available to the shell:
  - `qt6-multimedia` (Arch: `qt6-multimedia`)
  - FFmpeg backend: `qt6-multimedia-ffmpeg` (Arch) — required for video
    sinks (`VideoOutput`) and `MediaRecorder`-based functions on Linux.
- A V4L2 camera (built-in laptop webcam or any `v4l2` device). The plugin uses
  the first available `CameraDevice`.
- Write access to `~/Pictures/Camera` (created automatically on open).

## Installation

1. Clone/copy this directory into your plugins folder:

   ```sh
   git clone https://github.com/yashyaduari/omacam.git \
     ~/.config/omarchy/plugins/omacam
   ```

2. Register and enable it (adds it to the bar's `right` section):

   ```sh
   omarchy plugin validate ~/.config/omarchy/plugins/omacam
   omarchy plugin enable omacam right
   ```

3. Restart the shell:

   ```sh
   omarchy restart shell
   ```

You should now see a camera icon (`󰀀`) in the bar. Click it to open the
preview.

## Usage

- **Click the camera icon** to toggle the preview panel.
- **Snapshot**: saves a JPEG to `~/Pictures/Camera/`.
- **Mirror**: flips the preview horizontally.

### IPC

The panel is controllable from the command line / keybinds through Omarchy's
IPC (the module is registered as `camera`):

```sh
omarchy-shell camera open      # show the panel
omarchy-shell camera close     # hide the panel
omarchy-shell camera toggle    # toggle open/closed
```

Example Hyprland keybind:

```ini
bind = SUPER, C, exec, omarchy-shell camera toggle
```

## Configuration

Persist per-plugin settings in
`~/.config/omarchy/shell.json` under the plugin's entry:

```jsonc
{
  "id": "omacam",
  "mirror": false          // start with mirror OFF (default: true)
}
```

(You set `mirror` from the panel button too; it's a runtime toggle
persisted via Quickshell's `setting()`.)

## Files

```
CameraPanel.qml   — the popup panel: preview, mirror, snapshot, status
Widget.qml        — the bar icon button that opens/closes the panel
manifest.json     — plugin manifest (bar-widget entry point)
```

## Development

Omarchy hot-reloads local plugins on save. Edit a `.qml` file and the plugin
reloads automatically; force with:

```sh
omarchy-shell shell rescanPlugins
```

Validate the plugin at any time:

```sh
omarchy plugin validate ~/.config/omarchy/plugins/omacam
```

## Compatibility / notes

- Requires Qt 6.9+ for the `VideoOutput`/`CaptureSession` API used here.
- On some compositors/hardware the preview may need a moment to produce the
  first frame; the panel shows "Starting camera…" until then.
- Uses the first available camera. If your webcam shows a generic
  "MKV/ACER HD Camera" it's just the device's V4L2 description.
- The camera is only active while the panel is open (see "Features").
</content>
