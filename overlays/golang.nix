final: prev: rec {
  go = prev.go_1_23;

  ## `gocode` is fully deprecated, so replace it with a benign package.
  #gocode = go;

  ## pin golangci-lint to 1.55.2 for Dapr.
  #golangci-lint = let
  #  version = "1.55.2";
  #  src = prev.fetchFromGitHub {
  #    owner = "golangci";
  #    repo = "golangci-lint";
  #    rev = "v${version}";
  #    sha256 = "sha256-DO71wfDmCuziEcsme1g1uNIl3MswA+EkQcYzOYHbG+I=";
  #  };
  #in prev.golangci-lint.override rec {
  #  buildGo123Module = args: prev.buildGo121Module ( args // {
  #    inherit src version;
  #    go = prev.go_1_22;
  #    vendorHash = "sha256-0+jImfMdVocOczGWeO03YXUg5yKYTu3WeJaokSlcYFM=";
  #    ldflags = [
  #      "-s"
  #      "-w"
  #      "-X main.version=${version}"
  #      "-X main.commit=v${version}"
  #      "-X main.date=19700101-00:00:00"
  #    ];
  #  });
  #};
}
