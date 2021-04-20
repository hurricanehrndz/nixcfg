inputs@{ ... }:
final: prev:

{
  powershell = prev.powershell.overrideAttrs (old: {
    installPhase = ''
      chmod +x pwsh
    '' + old.installPhase;
    installCheckPhase = "";
  });
}
