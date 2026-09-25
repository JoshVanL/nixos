{ inputs }:
final: prev:
let
  unstable = import inputs.nixpkgs-unstable { inherit (prev) system; };
  # go_1_26_4 comes from the golang overlay, which is applied first.
  buildGoModule' = unstable.buildGo126Module.override { go = final.go_1_26_4; };
in
{
  dapr-cli = prev.dapr-cli.override {
    buildGoModule = fnOrAttrs:
      let
        wrapFn = finalAttrs:
          let
            orig = if builtins.isFunction fnOrAttrs then fnOrAttrs finalAttrs else fnOrAttrs;
          in orig // rec {
            version = "1.18.0";
            src = prev.fetchFromGitHub {
              owner = "dapr";
              repo = "cli";
              rev = "v${version}";
              sha256 = "sha256-2zi8r4LIguWPrsvpvz+sYF4sXqBVmWJtzHLm5nRHFCU=";
            };
            vendorHash = "sha256-P7zrfUcb/Hxo7QbIQfq9JSf2d7meZShQ++GG8HkEoLE=";
            ldflags = [
              "-X main.version=${version}"
              "-X main.apiVersion=1.0"
              "-X github.com/dapr/cli/pkg/standalone.gitcommit=${src.rev}"
              "-X github.com/dapr/cli/pkg/standalone.gitversion=${version}"
            ];
          };
      in buildGoModule' wrapFn;
  };
}
