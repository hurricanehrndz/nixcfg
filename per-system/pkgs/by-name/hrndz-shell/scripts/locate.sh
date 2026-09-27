# locate: prints "<latitude> <longitude>" from GeoClue's Wi-Fi source
# (nearby access points looked up in BeaconDB), or nothing. When it prints
# nothing, the weather panel lets wttr.in locate by public IP instead.
# GeoClue's own IP source stays off: the NixOS module writes no [ip] method.

timeout 10 where-am-i --timeout 8 2>/dev/null |
  awk '
    /^Latitude:/ { gsub(/°/, "", $2); lat = $2 }
    /^Longitude:/ { gsub(/°/, "", $2); print lat, $2; exit }
  ' || true
