{pkgs, ...}: {
  homebrew.brews = [
    "tinygo"
    # required for tinyGO
    "binaryen"
  ];
  homebrew.taps = [
    "tinygo-org/tools"
  ];
  environment.systemPackages = with pkgs; [
    esptool
  ];
}
