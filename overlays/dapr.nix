{ inputs }:
final: prev:
let
  unstable = import inputs.nixpkgs-unstable { inherit (prev) system; };
in
{
  dapr-cli = prev.dapr-cli.override {
    buildGoModule = fnOrAttrs:
      let
        wrapFn = finalAttrs:
          let
            orig = if builtins.isFunction fnOrAttrs then fnOrAttrs finalAttrs else fnOrAttrs;
          in orig // rec {
            version = "1.17.1";
            src = prev.fetchFromGitHub {
              owner = "dapr";
              repo = "cli";
              rev = "v${version}";
              sha256 = "sha256-XsRMVuXkHRARQ2UhG317QH0Ub4SOG8mesa7PnesXpvc=";
            };
            vendorHash = "sha256-WwYpoKyiNbeoXnOaRy94vSoG4Ya1a7DYNriZoZuBRF8=";
            ldflags = [
              "-X main.version=${version}"
              "-X main.apiVersion=1.0"
              "-X github.com/dapr/cli/pkg/standalone.gitcommit=${src.rev}"
              "-X github.com/dapr/cli/pkg/standalone.gitversion=${version}"
            ];
          };
      in unstable.buildGo126Module wrapFn;
  };
}
