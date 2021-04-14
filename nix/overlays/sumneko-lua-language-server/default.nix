inputs@{ lua-language-server, ... }:
final: prev:
let
  # fetch submodules for input
  fixed_lua-language-server = builtins.fetchGit {
    url = "https://github.com/sumneko/lua-language-server.git";
    inherit (inputs.lua-language-server) rev;
    submodules = true;
  };
in {
  sumneko-lua-language-server = prev.sumneko-lua-language-server.overrideAttrs
    (old: rec {
      version = src.shortRev;
      src = fixed_lua-language-server;
      # preConfigure = ''
      #   sed -ribak -e 's%if \(::utimensat.*%if (::utimes(p.c_str(), times) != 0) {%g' 3rd/bee.lua/bee/nonstd/filesystem.h
      #   sed -ribak -e 's%if \(::utimensat.*%if (::utimes(p.c_str(), times) != 0) {%g' 3rd/luamake/3rd/bee.lua/bee/nonstd/filesystem.h
      # '';
      patches = (if prev.stdenv.isDarwin then [ ./darwin.patch ] else [ ]);
      ninjaFlags = (if prev.stdenv.isDarwin then
        [ "-f compile/ninja/macos.ninja" ]
      else
        [ "-f compile/ninja/linux.ninja" ]);

      nativeBuildInputs = old.nativeBuildInputs
        ++ prev.lib.optional prev.stdenv.isDarwin
        (with prev.darwin.apple_sdk.frameworks; [ CoreServices prev.gcc ]);
    });
}
