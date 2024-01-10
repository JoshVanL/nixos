{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "go-protobuf";
  version = "1.32.0";

  src = fetchFromGitHub {
    owner = "protocolbuffers";
    repo = "protobuf-go";
    rev = "v${version}";
    hash = "sha256-7i6neRiC0fdn5wnPDp7vCDPlVglzt7tDR0qtG9V/qZA=";
  };

  vendorHash  = "sha256-nGI/Bd6eMEoY0sBwWEtyhFowHVvwLKjbT4yfzFz6Z3E=";
  subPackages = [ "cmd/protoc-gen-go" ];
}
