{ stdenv, lib, fetchFromGitHub, rustPlatform, pkgconfig, openssl, darwin }:

rustPlatform.buildRustPackage rec {
  pname = "sheldon";
  version = "0.6.2";
  doCheck = false;

  src = fetchFromGitHub {
    owner = "rossmacarthur";
    repo = pname;
    rev = version;
    sha256 = "sha256-LbSCwBwUC6vD3Dt0uauweBuwp5J755z15R8QAJOZd/w=";
  };

  cargoSha256 = "sha256-osa4BRp67QqZM1X1TDhlVN2tfnyKlcfmmh7j2cQAs1I=";

  nativeBuildInputs = [ pkgconfig ];
  buildInputs = [ openssl ]
  ++ lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.Security
  ];

  meta = with lib; {
    description = "Fast, configurable, shell plugin manager ";
    homepage = https://github.com/rossmacarthur/sheldon;
    license = with licenses; [ asl20 /* or */ mit ];
    platforms = platforms.all;
    maintainers = [ maintainers.hurricanehrndz ];
  };
}
