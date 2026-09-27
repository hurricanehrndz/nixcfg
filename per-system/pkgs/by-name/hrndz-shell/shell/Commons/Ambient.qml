pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The ambient video and its still frame, which ambient-set picks (a sharp,
// well-exposed key frame) and records the time of. The wallpaper shows the
// still; the screensaver and lock screen play the video from that time, as
// the login screen does, so it starts on the picture already shown. The NixOS module keeps both in a system directory the greeter can
// read; `ambient-set` installs them and then calls `reload`. Without them
// the Stylix image stands in, and without that the background colour.
Singleton {
  id: root

  readonly property string dir: "@ambientDir@"
  readonly property string home: Quickshell.env("HOME")
  // Home Manager links the Stylix image here when the scheme has one.
  readonly property string stylixImage: home + "/.config/hrndz-shell/background"

  property bool hasVideo: false
  property bool hasStill: false
  property bool hasStylixImage: false
  // Where the still is in the video, in milliseconds.
  property real start: 0
  // Bumped on reload so views reopen a replaced file under the same name.
  property int version: 0

  readonly property string videoUrl: hasVideo ? "file://" + dir + "/video" : ""
  readonly property string imageUrl: hasStill
    ? "file://" + dir + "/still.jpg?v=" + version
    : (hasStylixImage ? "file://" + stylixImage.split("/").map(encodeURIComponent).join("/") : "")

  // Runtime state, from the lock service, hypridle and the dpms helper.
  property bool displaysOn: true
  property bool locked: false
  property bool screensaver: false
  // Where the screensaver's playback is, so the lock screen taking over from
  // it carries on from there instead of cutting back to the start.
  property real screensaverPosition: 0

  function reload() {
    if (!probe.running) probe.running = true
  }

  Process {
    id: probe
    running: true
    command: ["bash", "-c",
      "[[ -r $0/video ]] && echo video; [[ -r $0/still.jpg ]] && echo still; "
      + "[[ -e $1 ]] && echo image; [[ -r $0/start ]] && echo \"start=$(<$0/start)\"; true",
      root.dir, root.stylixImage]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var found = String(text || "").split("\n")
        root.hasVideo = found.indexOf("video") !== -1
        root.hasStill = found.indexOf("still") !== -1
        root.hasStylixImage = found.indexOf("image") !== -1
        var start = found.filter(function(line) { return line.indexOf("start=") === 0 })[0]
        root.start = start ? Math.round(parseFloat(start.slice(6)) * 1000) || 0 : 0
        root.version += 1
      }
    }
  }

  IpcHandler {
    target: "ambient"

    function reload(): void {
      root.reload()
    }

    function screensaver(): void {
      if (!root.locked) root.screensaver = true
    }

    function hideScreensaver(): void {
      root.screensaver = false
    }

    function displays(on: bool): void {
      root.displaysOn = on
    }

    function status(): string {
      return JSON.stringify({
        video: root.hasVideo,
        still: root.hasStill,
        displaysOn: root.displaysOn,
        locked: root.locked,
        screensaver: root.screensaver
      })
    }
  }
}
