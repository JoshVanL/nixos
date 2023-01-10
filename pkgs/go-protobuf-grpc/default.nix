{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "go-protobuf-grpc";
  version = "1.50.1";

  src = fetchFromGitHub {
    owner = "grpc";
    repo = "grpc-go";
    rev = "v${version}";
    sha256 = "sha256-TAPVXhEA1XrQmPNm6/mF0F6e8CpOhdK2wEwL3iJhBK0=";
  };

  modRoot = "cmd/protoc-gen-go-grpc";

  vendorSha256  = "sha256-yxOfgTA5IIczehpWMM1kreMqJYKgRT5HEGbJ3SeQ/Lg=";
}
