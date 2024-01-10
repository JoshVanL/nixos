{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "go-protobuf-grpc";
  version = "1.60.0";

  src = fetchFromGitHub {
    owner = "grpc";
    repo = "grpc-go";
    rev = "v${version}";
    sha256 = "sha256-G37EG4R3+CtXWqqwx+VlAmpjrlO+CkEhO9GBBaE2Dr0=";
  };

  modRoot = "cmd/protoc-gen-go-grpc";

  vendorHash  = "sha256-STnw/83IaxD3iwiD4ep9oRj8Hoiso0bG1556mrAgK28=";
}
