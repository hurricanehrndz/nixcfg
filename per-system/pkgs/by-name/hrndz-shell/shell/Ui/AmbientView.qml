import QtQuick
import QtMultimedia
import qs.Commons

// The ambient still (or the Stylix image, or the background colour) and,
// with `video`, the video playing over it, muted and looping. Playback seeks
// to the still's key frame first, so it starts on the picture already shown,
// and loops through the whole video from there.
// `playing` pauses on the current frame; unsetting `video` drops the player,
// so the next start is from the still again.
// CEILING: one decoder per view, so each output decodes the file on its own.
// Fine for one or two monitors; sharing frames across windows would need one
// VideoSink feeding textures to each.
Rectangle {
  id: root

  property bool video: false
  property bool playing: true
  // The screensaver publishes its position; the lock screen resumes from it
  // when it takes over from a running screensaver.
  property bool publishPosition: false
  property bool resume: false

  color: Color.background

  Image {
    anchors.fill: parent
    source: Ambient.imageUrl
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: false
    // Wider than GL_MAX_TEXTURE_SIZE renders black with no error.
    sourceSize.width: Math.min(4096, root.width)
  }

  Loader {
    anchors.fill: parent
    active: root.video && Ambient.hasVideo
    sourceComponent: Item {
      id: stage

      property real pendingSeek: -1

      MediaPlayer {
        id: player
        source: Ambient.videoUrl
        loops: MediaPlayer.Infinite
        videoOutput: output
        // No audioOutput: nothing is decoded for sound.
        onErrorOccurred: function(error, message) { console.warn("ambient: " + message) }
        onPositionChanged: if (root.publishPosition) Ambient.screensaverPosition = player.position
        onMediaStatusChanged: {
          if (stage.pendingSeek >= 0 && mediaStatus === MediaPlayer.LoadedMedia) {
            position = stage.pendingSeek
            stage.pendingSeek = -1
            stage.sync()
          }
        }
      }

      VideoOutput {
        id: output
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
      }

      // Held back until the seek, so no frame from before it shows.
      function sync() {
        if (root.playing && pendingSeek < 0) player.play()
        else if (player.playbackState === MediaPlayer.PlayingState) player.pause()
      }

      Connections {
        target: root
        function onPlayingChanged() { stage.sync() }
      }

      // ambient-set replaced the file under the same name.
      Connections {
        target: Ambient
        function onVersionChanged() {
          player.stop()
          player.source = ""
          stage.pendingSeek = Ambient.start
          player.source = Ambient.videoUrl
        }
      }

      Component.onCompleted: {
        pendingSeek = root.resume && Ambient.screensaver ? Ambient.screensaverPosition : Ambient.start
        if (player.mediaStatus === MediaPlayer.LoadedMedia) player.mediaStatusChanged()
        sync()
      }
    }
  }
}
