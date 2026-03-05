{ inputs }:
final: prev:
let
  unstable = import inputs.nixpkgs-unstable { inherit (prev) system; };
in
{
  #go = prev.go_1_24;
  #go = prev.go_1_23;
  #go = prev.go_1_22;

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
