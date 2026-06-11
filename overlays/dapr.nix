{ inputs }:
final: prev:
let
  unstable = import inputs.nixpkgs-unstable { inherit (prev) system; };
  # dapr cli 1.18.0 and its github.com/dapr/dapr dependency require
  # go >= 1.26.4, but unstable only ships 1.26.3.
  go_1_26_4 = unstable.go_1_26.overrideAttrs (old: rec {
    version = "1.26.4";
    src = prev.fetchurl {
      url = "https://go.dev/dl/go${version}.src.tar.gz";
      hash = "sha256-T2aKMvv8ETLmqIH7lowvHa2mMUkqM5IRc1+7JVpCYC0=";
    };
  });
  buildGoModule' = unstable.buildGo126Module.override { go = go_1_26_4; };
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
