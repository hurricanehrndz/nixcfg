import QtQuick
import QtQuick.Effects
import QtMultimedia

// The login screen: the ambient video (or its still, or the background
// colour) softly blurred and dimmed, a large clock and a password field for
// the last user, after qylock's winter theme. The only session is
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
      root.failure = "Access denied"
      password.text = ""
      shake.start()
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
      source: "file://" + root.ambientDir + "/still.png"
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
      playbackRate: parseFloat(config.playbackRate) || 1.0
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

  // Every size scales with the screen, from a 1920x1080 design (qylock's
  // winter theme); min() keeps ultrawide and tall screens in proportion.
  readonly property real s: Math.min(width / 1920, height / 1080)

  // Darkens the lower half so the field and links read on bright video.
  Rectangle {
    anchors.fill: parent
    visible: root.mediaBehind
    gradient: Gradient {
      GradientStop { position: 0.5; color: "transparent" }
      GradientStop { position: 1.0; color: Qt.alpha(root.color.hslLightness < 0.5 ? root.color : "black", 0.6) }
    }
  }

  Column {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: 120 * root.s
    spacing: 15 * root.s
    layer.enabled: root.mediaBehind
    layer.effect: MultiEffect {
      shadowEnabled: true
      shadowOpacity: 0.35
      shadowBlur: 0.6
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: Qt.formatTime(root.now, "HH:mm")
      color: root.clockColor
      font.family: root.font
      font.pixelSize: 180 * root.s
      font.weight: Font.Thin
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: Qt.formatDate(root.now, "dddd, MMMM d").toUpperCase()
      color: root.clockColor
      opacity: 0.85
      font.family: root.font
      font.pixelSize: 18 * root.s
      font.letterSpacing: 12 * root.s
      font.weight: Font.DemiBold
    }
  }

  Column {
    id: login
    anchors.centerIn: parent
    anchors.verticalCenterOffset: 160 * root.s
    width: 400 * root.s
    spacing: 25 * root.s

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.realName.toUpperCase()
      color: root.clockColor
      font.family: root.font
      font.pixelSize: 18 * root.s
      font.letterSpacing: 3 * root.s
      font.weight: Font.Bold
    }

    // A borderless field over a hairline that widens on focus. The dots
    // shrink to fit once the password outgrows the width, so every keystroke
    // stays visible.
    Item {
      id: field
      anchors.horizontalCenter: parent.horizontalCenter
      width: 320 * root.s
      height: 50 * root.s

      TextMetrics {
        id: dotMetrics
        font.family: root.font
        font.pixelSize: 32 * root.s
        font.letterSpacing: 10 * root.s
        text: "·".repeat(password.text.length)
      }

      TextInput {
        id: password
        width: parent.width
        height: parent.height
        verticalAlignment: TextInput.AlignVCenter
        horizontalAlignment: TextInput.AlignHCenter
        echoMode: TextInput.Password
        passwordCharacter: "·"
        passwordMaskDelay: 0
        clip: true
        focus: true
        enabled: !root.authenticating
        color: root.clockColor
        selectionColor: root.accent
        font.family: root.font
        font.pixelSize: dotMetrics.advanceWidth > width
          ? Math.max(8, Math.floor(32 * root.s * (width - 4) / dotMetrics.advanceWidth))
          : 32 * root.s
        font.letterSpacing: dotMetrics.advanceWidth > width ? 2 * root.s : 10 * root.s
        onAccepted: root.login()
        onTextChanged: if (text.length > 0) root.failure = ""
        Keys.onEscapePressed: text = ""

        SequentialAnimation {
          id: shake
          NumberAnimation { target: password; property: "x"; to: -10 * root.s; duration: 50 }
          NumberAnimation { target: password; property: "x"; to: 10 * root.s; duration: 50 }
          NumberAnimation { target: password; property: "x"; to: -10 * root.s; duration: 50 }
          NumberAnimation { target: password; property: "x"; to: 10 * root.s; duration: 50 }
          NumberAnimation { target: password; property: "x"; to: 0; duration: 50 }
        }
      }

      Text {
        anchors.centerIn: parent
        visible: password.text.length === 0
        text: root.authenticating ? "CHECKING" : "PASSWORD"
        color: root.clockColor
        opacity: 0.6
        font.family: root.font
        font.pixelSize: 14 * root.s
        font.letterSpacing: 6 * root.s
      }

      Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        height: Math.max(1, Math.round(root.s))
        width: password.activeFocus ? parent.width : parent.width * 0.3
        color: root.failure ? root.error : root.clockColor
        opacity: password.activeFocus ? 0.8 : 0.2
        Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
        Behavior on opacity { NumberAnimation { duration: 350 } }
      }
    }

    Text {
      width: parent.width
      height: 15 * root.s
      horizontalAlignment: Text.AlignHCenter
      text: root.failure.toUpperCase()
      color: root.error
      font.family: root.font
      font.pixelSize: 10 * root.s
      font.letterSpacing: 2 * root.s
    }
  }

  Row {
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: 50 * root.s
    spacing: 25 * root.s

    Repeater {
      model: [
        { label: "REBOOT", enabled: sddm.canReboot, run: function() { sddm.reboot() } },
        { label: "SHUTDOWN", enabled: sddm.canPowerOff, run: function() { sddm.powerOff() } }
      ]
      delegate: Text {
        required property var modelData
        visible: modelData.enabled
        text: modelData.label
        color: root.clockColor
        opacity: hover.containsMouse ? 1 : 0.6
        font.family: root.font
        font.pixelSize: 12 * root.s
        font.letterSpacing: 2 * root.s

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
