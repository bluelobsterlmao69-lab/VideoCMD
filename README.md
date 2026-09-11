
# VideoCMD

**Play videos inside Windows Command Prompt.**

VideoCMD converts short videos into low-resolution frames and renders them directly inside the terminal.

Because apparently, VLC wasn't great enough

## ✨ Features

* 🎥 MP4, GIF, AVI, MOV, MKV, and WEBM support
* ⏱️ Videos up to 10 seconds
* 🎞️ Frame-by-frame terminal playback
* 🖥️ Runs inside Windows CMD
* ⚙️ Uses FFmpeg for video conversion
* 🎨 256 ANSI color
* 📂 Built-in file picker
* 🧹 Automatic temporary-file cleanup
* 🔇 No sound...

## 📦 Requirements

* Windows
* FFmpeg
* PowerShell
* Command Prompt

FFmpeg must be installed and available in your system `PATH`.

Check if FFmpeg is working by opening CMD and running:

ffmpeg -version

## 🚀 Installation

1. Download the repository.
2. Put `VideoCMD.bat` and `VideoCMD.ps1` in the same folder.
3. Make sure FFmpeg is installed and available through PATH.
4. Run 'VideoCMD.bat'

5. Select a video.
6. Watch it play in CMD. 🎬

## 🎮 Example

VideoCMD was tested with a *60 FPS Geometry Dash recording*, so yeah, it's great.

## ⚙️ Current Settings

| Setting              |                 Value |
| -------------------- | --------------------: |
| Maximum video length |              1 minute |
| Input FPS            |                   Any |
| Playback FPS         |                   ~30 |
| Resolution           |               50 × 25 |
| Color                |        256 ANSI Color |
| Renderer             |            PowerShell |
| Conversion           |                FFmpeg |

## 🧪 Status

**Experimental**

VideoCMD is a fun terminal video renderer rather than a replacement for a normal video player.

Expect low resolution and some visual weirdness.

### Why?

because, yeah.
