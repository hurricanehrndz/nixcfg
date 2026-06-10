{ pkgs, ... }:

pkgs.buildGoModule rec {
  pname = "html-to-markdown";
  version = "2.5.1";

  src = pkgs.fetchFromGitHub {
    owner = "JohannesKaufmann";
    repo = "html-to-markdown";
    rev = "v${version}";
    hash = "sha256-SFN1rXlJdkNu0xq6MzW3TGMo1HGfFtU/7kMfkEkKFEQ=";
  };

  vendorHash = "sha256-JWusYN482+ei2kqiGYnAVfBGbdfThu8LHBX3JhMU6FE=";

  subPackages = [ "cli/html2markdown" ];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  meta = {
    description = "Convert HTML into Markdown";
    homepage = "https://github.com/JohannesKaufmann/html-to-markdown";
    license = pkgs.lib.licenses.mit;
    mainProgram = "html2markdown";
  };
}
