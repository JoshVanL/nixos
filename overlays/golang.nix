final: prev: rec {
  #go = prev.go_1_24;
  #go = prev.go_1_23;
  #go = prev.go_1_22;

  # pin golangci-lint to 1.61.0 for Dapr.
  #golangci-lint = let
  #  version = "1.64.6";
  #  src = prev.fetchFromGitHub {
  #    owner = "golangci";
  #    repo = "golangci-lint";
  #    rev = "v${version}";
  #    sha256 = "sha256-2YzVNOdasal27R92l6eVdeS81mAp0ZU6kYsC/Jfvkca=";
  #  };
  #in prev.golangci-lint.override rec {
  #    buildGo124Module = args: prev.buildGo124Module ( args // {
  #      inherit src version;
  #      vendorHash = "sha256-mFDCRxbLq08yRd0ko3CCPJD2BZiCB0Gwd1g+/1oR6wa=";
  #      ldflags = [
  #        "-s"
  #        "-w"
  #        "-X main.version=${version}"
  #        "-X main.commit=v${version}"
  #        "-X main.date=19700101-00:00:00"
  #      ];
  #    });
  #};

   golangci-lint = prev.golangci-lint.overrideAttrs (oldAttrs: rec {
    version = "1.64.4";
    src = prev.fetchFromGitHub {
      owner = "golangci";
      repo = "golangci-lint";
      rev = "v${version}";
      sha256 = "sha256-BrkBIf4WP3COAac/5vre8fHLgDneg5Gm31nNq8sXzEE=";
    };
    vendorHash = "sha256-xUKse9yTAVuysmPwmX4EXdlpg6NYKfT5QB1RgmBQvhk=";
  });
}
