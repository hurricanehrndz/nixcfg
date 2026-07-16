{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "pfdump";
      bashOptions = [ ];
      text = ''
        pfprint() {
          /usr/bin/sudo pfctl -a "$2" -s"$1" 2>/dev/null
        }

        pfprint_all() {
          local anchor indent a
          printf -v anchor "%-40s" "''${1:-/}"
          printf -v indent "%-40s" ""

          (
            pfprint r "$1" | /usr/bin/sed "s,^,r     ,"
            pfprint n "$1" | /usr/bin/sed "s,^,n     ,"
            pfprint A "$1" | /usr/bin/sed "s,^,A ,"
          ) | /usr/bin/sed -e "1s,^,''${anchor}," -e "2,\$s,^,''${indent},"

          while IFS= read -r a; do
            pfprint_all "$a"
          done < <(pfprint A "$1")
        }

        pfprint_all
      '';

      meta = {
        description = "Dump macOS packet filter anchors";
        platforms = pkgs.lib.platforms.darwin;
      };
    })
  ];
}
