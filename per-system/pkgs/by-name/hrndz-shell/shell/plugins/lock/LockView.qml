import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Commons
import qs.Ui

Item {
  id: root

  property bool fingerprintConfigured: false
  property bool authenticatingPassword: false
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool inputEnabled: true
  property bool loadBackground: true
  property string passwordText: ""
  property bool syncingPasswordText: false

  property string realName: ""

  // Laid out like the login screen (hrndz-sddm-theme's Main.qml): every size
  // scales from its 1920x1080 design, and min() keeps ultrawide and tall
  // screens in proportion. Change the two together.
  readonly property real s: Math.min(width / 1920, height / 1080)
  readonly property real fieldWidth: 320 * s
  readonly property real passwordDotFontSize: 32 * s
  readonly property real passwordDotLetterSpacing: 10 * s
  // Room on each side of the field for the fingerprint icon, so the centered
  // dots never run under it.
  readonly property real fingerprintReserve: fingerprintConfigured ? Math.round(fingerprintIcon.implicitWidth + 8 * s) : 0
  // Shrink the dots to fit once the password outgrows the field, so every
  // keystroke stays visible.
  readonly property bool dotsOverflow: dotMetrics.advanceWidth > passwordInput.width
  readonly property bool showPasswordCursor: inputEnabled && !authenticatingPassword && failureMessage.length === 0
  readonly property bool errorState: failureMessage.length > 0

  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()

  // The clock sits on the ambient video or image, dimmed, where the lighter of
  // the scheme's two base colours reads; on the plain colour it is the text.
  readonly property bool mediaBehind: Ambient.imageUrl !== "" || Ambient.hasVideo
  readonly property color clockColor: !mediaBehind ? Color.foreground
    : (Color.foreground.hslLightness > Color.background.hslLightness ? Color.foreground : Color.background)

  function forcePasswordFocus() {
    passwordInput.forceActiveFocus()
  }

  function clearPassword() {
    passwordTextEdited("")
  }

  function syncPasswordText() {
    if (passwordInput.text === passwordText) return
    syncingPasswordText = true
    passwordInput.text = passwordText
    syncingPasswordText = false
  }

  onPasswordTextChanged: syncPasswordText()
  onFailedAttemptsChanged: if (failedAttempts > 0) shake.restart()
  onInputEnabledChanged: {
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }
  Component.onCompleted: {
    syncPasswordText()
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }

  TextMetrics {
    id: dotMetrics
    font.family: Style.font.family
    font.pixelSize: root.passwordDotFontSize
    font.letterSpacing: root.passwordDotLetterSpacing
    text: "\u00B7".repeat(passwordInput.text.length)
  }

  Rectangle {
    anchors.fill: parent
    color: Color.background

    // The ambient video, softly blurred and dimmed, from the wallpaper's
    // frame or from where the screensaver was. It pauses with the displays
    // off.
    AmbientView {
      id: wallpaper
      anchors.fill: parent
      visible: false
      video: root.loadBackground
      playing: Ambient.displaysOn
      resume: true
    }

    MultiEffect {
      anchors.fill: wallpaper
      source: wallpaper
      autoPaddingEnabled: false
      blurEnabled: root.mediaBehind
      blur: 0.35
      blurMax: 64
      brightness: root.mediaBehind ? -0.18 : 0
    }

    // Darkens the lower half so the field reads on bright video.
    Rectangle {
      anchors.fill: parent
      visible: root.mediaBehind
      gradient: Gradient {
        GradientStop { position: 0.5; color: "transparent" }
        GradientStop { position: 1.0; color: Qt.alpha(Color.background.hslLightness < 0.5 ? Color.background : "black", 0.6) }
      }
    }

    SystemClock {
      id: clock
      precision: SystemClock.Minutes
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
        text: Qt.formatTime(clock.date, "HH:mm")
        color: root.clockColor
        font.family: Style.font.family
        font.pixelSize: 180 * root.s
        font.weight: Font.Thin
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDate(clock.date, "dddd, MMMM d").toUpperCase()
        color: root.clockColor
        opacity: 0.85
        font.family: Style.font.family
        font.pixelSize: 18 * root.s
        font.letterSpacing: 12 * root.s
        font.weight: Font.DemiBold
      }
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onClicked: { root.wakeRequested(); root.forcePasswordFocus() }
      onPositionChanged: root.wakeRequested()
    }

    Column {
      anchors.centerIn: parent
      anchors.verticalCenterOffset: 160 * root.s
      width: 400 * root.s
      spacing: 25 * root.s

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.realName.length > 0
        text: root.realName.toUpperCase()
        color: root.clockColor
        font.family: Style.font.family
        font.pixelSize: 18 * root.s
        font.letterSpacing: 3 * root.s
        font.weight: Font.Bold
      }

      // A borderless field over a hairline that widens on focus.
      Item {
        id: inputField
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.fieldWidth
        height: 50 * root.s

        TextInput {
          id: passwordInput
          anchors.fill: parent
          anchors.leftMargin: root.fingerprintReserve
          anchors.rightMargin: root.fingerprintReserve
          verticalAlignment: TextInput.AlignVCenter
          horizontalAlignment: TextInput.AlignHCenter
          activeFocusOnPress: true
          clip: true
          enabled: root.inputEnabled && !root.authenticatingPassword
          readOnly: root.authenticatingPassword
          echoMode: TextInput.Password
          passwordCharacter: "\u00B7"
          passwordMaskDelay: 0
          color: root.clockColor
          selectionColor: Color.lock.selection
          selectedTextColor: root.clockColor
          font.family: Style.font.family
          font.pixelSize: root.dotsOverflow
            ? Math.max(8, Math.floor(root.passwordDotFontSize * (width - 4) / dotMetrics.advanceWidth))
            : root.passwordDotFontSize
          font.letterSpacing: root.dotsOverflow ? 2 * root.s : root.passwordDotLetterSpacing
          cursorVisible: activeFocus && root.showPasswordCursor && text.length > 0
          cursorDelegate: Rectangle {
            width: Math.max(1, Math.round(root.s))
            color: root.clockColor
            visible: passwordInput.cursorVisible
          }

          onTextChanged: {
            if (!root.syncingPasswordText) root.passwordTextEdited(text)
            if (text.length > 0) {
              root.wakeRequested()
            }
            if (text.length > 0 && root.failureMessage.length > 0) root.clearFailureRequested()
          }

          onAccepted: {
            var submitted = root.passwordText
            root.passwordTextEdited("")
            if (submitted.length > 0) root.submitPassword(submitted)
          }

          Keys.onPressed: function(event) {
            root.wakeRequested()
            if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
              root.passwordTextEdited("")
              event.accepted = true
            }
          }
        }

        SequentialAnimation {
          id: shake
          NumberAnimation { target: inputField; property: "anchors.horizontalCenterOffset"; to: -10 * root.s; duration: 50 }
          NumberAnimation { target: inputField; property: "anchors.horizontalCenterOffset"; to: 10 * root.s; duration: 50 }
          NumberAnimation { target: inputField; property: "anchors.horizontalCenterOffset"; to: -10 * root.s; duration: 50 }
          NumberAnimation { target: inputField; property: "anchors.horizontalCenterOffset"; to: 10 * root.s; duration: 50 }
          NumberAnimation { target: inputField; property: "anchors.horizontalCenterOffset"; to: 0; duration: 50 }
        }

        Text {
          textFormat: Text.PlainText
          anchors.centerIn: parent
          visible: passwordInput.text.length === 0
          text: root.authenticatingPassword ? "CHECKING" : "PASSWORD"
          color: root.clockColor
          opacity: 0.6
          font.family: Style.font.family
          font.pixelSize: 14 * root.s
          font.letterSpacing: 6 * root.s
        }

        // Shown when a sensor is enrolled, so the user knows a touch unlocks.
        Text {
          id: fingerprintIcon
          objectName: "fingerprintIndicator"
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          visible: root.fingerprintConfigured
          text: "󰈷"
          color: root.clockColor
          opacity: 0.6
          font.family: Style.font.family
          font.pixelSize: 20 * root.s
        }

        Rectangle {
          anchors.bottom: parent.bottom
          anchors.horizontalCenter: parent.horizontalCenter
          height: Math.max(1, Math.round(root.s))
          width: passwordInput.activeFocus ? parent.width : parent.width * 0.3
          color: root.errorState ? Color.lock.textError : root.clockColor
          opacity: passwordInput.activeFocus ? 0.8 : 0.2
          Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
          Behavior on opacity { NumberAnimation { duration: 350 } }
        }
      }

      Text {
        textFormat: Text.PlainText
        width: parent.width
        height: 15 * root.s
        horizontalAlignment: Text.AlignHCenter
        text: root.failureMessage.toUpperCase()
        color: Color.lock.textError
        font.family: Style.font.family
        font.pixelSize: 10 * root.s
        font.letterSpacing: 2 * root.s
      }
    }
  }
}
