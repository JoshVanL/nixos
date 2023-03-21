{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "go-protobuf";
  version = "1.28.1";

  src = fetchFromGitHub {
    owner = "protocolbuffers";
    repo = "protobuf-go";
    rev = "v${version}";
    hash = "sha256-7Cg7fByLR9jX3OSCqJfLw5PAHDQi/gopkjtkbobnyWM=";
  };

  vendorSha256  = "sha256-yb8l4ooZwqfvenlxDRg95rqiL+hmsn0weS/dPv/oD2Y=";
  subPackages = [ "cmd/protoc-gen-go" ];
}
