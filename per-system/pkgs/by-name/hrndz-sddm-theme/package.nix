# The SDDM login theme: the ambient video behind the lock screen's clock and
# password field (modules/internal/nixos/desktop/hyprland/sddm.nix). Its
# video backdrop follows qylock's themes (github.com/Darkkal44/qylock). The
# greeter needs QtMultimedia, which the NixOS module adds through
# services.displayManager.sddm.extraPackages.
{
  lib,
  stdenvNoCC,
  # Stylix base16 colours (withHashtag); the defaults only keep the flake's
  # package output buildable.
  colors ? {
    base00 = "#1e1e2e";
    base05 = "#cdd6f4";
    base08 = "#f38ba8";
    base0D = "#89b4fa";
  },
  font ? "monospace",
  ambientDir ? "/var/lib/ambient",
}:
stdenvNoCC.mkDerivation {
  pname = "hrndz-sddm-theme";
  version = "1.0";

  src = ./theme;

  dontWrapQtApps = true;

  installPhase = ''
    runHook preInstall

    theme=$out/share/sddm/themes/hrndz
    mkdir -p $theme
    cp -r . $theme/
    substituteInPlace $theme/theme.conf \
      --subst-var-by base00 "${colors.base00}" \
      --subst-var-by base05 "${colors.base05}" \
      --subst-var-by base08 "${colors.base08}" \
      --subst-var-by base0D "${colors.base0D}" \
      --subst-var-by font "${font}" \
      --subst-var-by ambientDir "${ambientDir}"

    runHook postInstall
  '';

  meta = {
    description = "SDDM theme playing the desktop's ambient video";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
