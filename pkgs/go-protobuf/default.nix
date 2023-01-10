{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "go-protobuf";
  version = "1.5.2";

  src = fetchFromGitHub {
    owner = "golang";
    repo = "protobuf";
    rev = "v${version}";
    hash = "sha256-E/6Qh8hWilaGeSojOCz8PzP9qnVqNG2DQLYJUqN3BdY=";
  };

  vendorSha256  = "sha256-CcJjFMslSUiZMM0LLMM3BR53YMxyWk8m7hxjMI9tduE=";
  subPackages = [ "protoc-gen-go" ];
}
