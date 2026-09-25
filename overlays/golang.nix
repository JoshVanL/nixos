{ inputs }:
final: prev:
let
  unstable = import inputs.nixpkgs-unstable { inherit (prev) system; };
in
{
  go_1_26 = unstable.go_1_26;

  # dapr cli 1.18.0, go-sdk 1.15.0 and their github.com/dapr/dapr dependency
  # require go >= 1.26.4, but unstable only ships 1.26.3.
  go_1_26_4 = unstable.go_1_26.overrideAttrs (old: rec {
    version = "1.26.4";
    src = prev.fetchurl {
      url = "https://go.dev/dl/go${version}.src.tar.gz";
      hash = "sha256-T2aKMvv8ETLmqIH7lowvHa2mMUkqM5IRc1+7JVpCYC0=";
    };
  });

  golangci-lint = prev.golangci-lint.override {
    buildGo125Module = fnOrAttrs:
      let
        wrapFn = finalAttrs:
          let
            orig = if builtins.isFunction fnOrAttrs then fnOrAttrs finalAttrs else fnOrAttrs;
          in orig // rec {
            version = "2.10.1";
            src = prev.fetchFromGitHub {
              owner = "golangci";
              repo = "golangci-lint";
              rev = "v${version}";
              sha256 = "sha256-rHttQ+QJ9JrFvgfoX68Y0lD6BUv/aoOpRRFvZ1BIGIs=";
            };
            vendorHash = "sha256-yREpROQJ300+mii7R2oiyDjOGcYXBpv3o/park0TJYE=";
            ldflags = [
              "-s"
              "-w"
              "-X main.version=${version}"
              "-X main.commit=v${version}"
              "-X main.date=19700101-00:00:00"
            ];
          };
      in unstable.buildGo126Module wrapFn;
  };
}
