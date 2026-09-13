{ pkgs, ... }:

pkgs.buildGoModule rec {
  pname = "respec";
  version = "0.5.0";

  src = pkgs.fetchFromGitHub {
    owner = "hurricanehrndz";
    repo = "respec";
    rev = "v${version}";
    hash = "sha256-AHXVeRjdP4bfM1sICiBTV5FLo0SFtsjnDS025GAIFeA=";
  };

  vendorHash = "sha256-r//lsV+RgJrMk2ErxzNDQpcURxIU3vAidj5BRIUA4qo=";

  nativeBuildInputs = [ pkgs.makeWrapper ];
  nativeCheckInputs = [ pkgs.git ];

  # The release tarball has no .git directory, so give the two tests that use
  # the source checkout their own repository fixture instead.
  postPatch = ''
    substituteInPlace cmd/stamp_test.go \
      --replace-fail '"--repo", "."' '"--repo", initGitRepo(t)'
  '';

  postInstall = ''
    wrapProgram $out/bin/respec --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.git ]}
  '';

  meta = {
    description = "Research, plan, and implement workflow for coding agents";
    homepage = "https://github.com/hurricanehrndz/respec";
    license = pkgs.lib.licenses.mit;
    mainProgram = "respec";
  };
}
