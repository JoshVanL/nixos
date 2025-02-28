final: prev: rec {
  go = prev.go_1_23;
  #go = prev.go_1_22;

  # pin golangci-lint to 1.61.0 for Dapr.
  #golangci-lint = let
  #  version = "1.61.0";
  #  src = prev.fetchFromGitHub {
  #    owner = "golangci";
  #    repo = "golangci-lint";
  #    rev = "v${version}";
  #    sha256 = "sha256-2YzVNOdasal27R92l6eVdeS81mAp0ZU6kYsC/Jfvkcg=";
  #  };
  #in prev.golangci-lint.override rec {
  #    buildGoModule = args: prev.buildGoModule ( args // {
  #      inherit src version;
  #      vendorHash = "sha256-mFDCRxbLq08yRd0ko3CCPJD2BZiCB0Gwd1g+/1oR6w8=";
  #      ldflags = [
  #        "-s"
  #        "-w"
  #        "-X main.version=${version}"
  #        "-X main.commit=v${version}"
  #        "-X main.date=19700101-00:00:00"
  #      ];
  #    });
  #};
}
