import QtQuick
import QtQuick.Effects
import QtMultimedia

// The login screen: the ambient video (or its still, or the background
// colour) softly blurred and dimmed, a large clock and a password field for
// the last user, laid out as the desktop's lock screen. The only session is
// preselected and not shown. Colours, font and the ambient directory come
// from theme.conf, filled in from Stylix at build time.
Rectangle {
  id: root

  readonly property string ambientDir: config.ambientDir
  readonly property color foreground: config.foreground
  readonly property color accent: config.accent
  readonly property color error: config.error
  readonly property string font: config.font
  // The lighter of the scheme's base colours reads on the dimmed video.
  readonly property color clockColor: foreground.hslLightness > color.hslLightness ? foreground : color

  property string userName: userModel.lastUser
  property string realName: ""
  property bool authenticating: false
  property string failure: ""
  property date now: new Date()

  color: config.background

  // Only the name comes from lastUser; the display name is in the model.
  Repeater {
    model: userModel
    delegate: Item {
      Component.onCompleted: {
        if (!root.userName && index === 0) root.userName = model.name
        if (model.name === root.userName) root.realName = model.realName || model.name
      }
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.now = new Date()
  }

  Connections {
    target: sddm
    function onLoginFailed() {
      root.authenticating = false
      root.failure = "Authentication failed"
      password.text = ""
      password.forceActiveFocus()
    }
  }

  function login() {
    if (authenticating || password.text.length === 0) return
    failure = ""
    authenticating = true
    sddm.login(userName, password.text, sessionModel.lastIndex)
  }

  Item {
    id: backdrop
    anchors.fill: parent
    visible: false

    Image {
      id: still
      anchors.fill: parent
      source: "file://" + root.ambientDir + "/still.jpg"
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      sourceSize.width: Math.min(4096, root.width)
    }

    // Starts on the still's frame (ambient-set records where it is), so the
    // picture only comes alive. A missing video leaves the still.
    MediaPlayer {
      id: player
      source: "file://" + root.ambientDir + "/video"
      loops: MediaPlayer.Infinite
      videoOutput: video
      property real start: -1

      onMediaStatusChanged: {
        if (mediaStatus === MediaPlayer.LoadedMedia) {
          if (start > 0) position = start
          play()
        }
      }

      Component.onCompleted: {
        // QML_XHR_ALLOW_FILE_READ is set for the greeter (sddm.nix).
        var request = new XMLHttpRequest()
        request.open("GET", "file://" + root.ambientDir + "/start", false)
        request.send()
        start = Math.round(parseFloat(request.responseText) * 1000) || 0
      }
    }

    VideoOutput {
      id: video
      anchors.fill: parent
      fillMode: VideoOutput.PreserveAspectCrop
    }
  }

  readonly property bool mediaBehind: still.status === Image.Ready || player.hasVideo

  MultiEffect {
    anchors.fill: parent
    source: backdrop
    autoPaddingEnabled: false
    blurEnabled: root.mediaBehind
    blur: 0.35
    blurMax: 64
    brightness: root.mediaBehind ? -0.18 : 0
  }

  Column {
    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round(parent.height * 0.12)
    layer.enabled: root.mediaBehind
    layer.effect: MultiEffect {
      shadowEnabled: true
      shadowOpacity: 0.35
      shadowBlur: 0.6
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: Qt.formatDate(root.now, "dddd d MMMM")
      color: root.clockColor
      font.family: root.font
      font.pixelSize: Math.round(root.height * 0.028)
      font.weight: Font.Medium
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: Qt.formatTime(root.now, "H:mm")
      color: root.clockColor
      font.family: root.font
      font.pixelSize: Math.round(root.height * 0.15)
      font.weight: Font.DemiBold
    }
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: field.top
    anchors.bottomMargin: 14
    text: root.realName
    color: root.clockColor
    font.family: root.font
    font.pixelSize: 20
    font.weight: Font.Medium
  }

  // The lock screen's field: square, on the scheme background, with the
  // Hyprland active-border colour.
  Rectangle {
    id: field
    anchors.centerIn: parent
    width: 381
    height: 67
    color: Qt.alpha(root.color, 0.8)
    border.width: 3
    border.color: root.failure ? root.error : root.accent

    TextInput {
      id: password
      anchors.fill: parent
      anchors.margins: 21
      verticalAlignment: TextInput.AlignVCenter
      horizontalAlignment: TextInput.AlignHCenter
      echoMode: TextInput.Password
      passwordCharacter: "●"
      passwordMaskDelay: 0
      clip: true
      focus: true
      enabled: !root.authenticating
      color: root.foreground
      font.family: root.font
      font.pixelSize: text.length > 0 ? 28 : 18
      onAccepted: root.login()
      onTextChanged: if (text.length > 0) root.failure = ""
      Keys.onEscapePressed: text = ""
    }

    Text {
      anchors.fill: password
      visible: password.text.length === 0
      text: root.authenticating ? "Checking…" : (root.failure || "Enter Password")
      color: root.failure ? root.error : Qt.alpha(root.foreground, 0.6)
      font.family: root.font
      font.pixelSize: 18
      font.italic: root.failure !== ""
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
    }
  }

  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Math.round(parent.height * 0.06)
    spacing: 48

    Repeater {
      model: [
        { label: "Restart", enabled: sddm.canReboot, run: function() { sddm.reboot() } },
        { label: "Shut Down", enabled: sddm.canPowerOff, run: function() { sddm.powerOff() } }
      ]
      delegate: Text {
        required property var modelData
        visible: modelData.enabled
        text: modelData.label
        color: root.clockColor
        opacity: hover.containsMouse ? 1 : 0.7
        font.family: root.font
        font.pixelSize: 16

        MouseArea {
          id: hover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: parent.modelData.run()
        }
      }
    }
  }

  Component.onCompleted: password.forceActiveFocus()
}
