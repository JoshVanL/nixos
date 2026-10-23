final: prev:
{
  # nixpkgs 26.05 ships dapr-cli 1.17.1; keep the newer release. Its go.mod
  # needs go >= 1.26.4, which 26.05's buildGo126Module (1.26.8) satisfies.
  dapr-cli = prev.dapr-cli.override {
    buildGoModule = fnOrAttrs:
      let
        wrapFn = finalAttrs:
          let
            orig = if builtins.isFunction fnOrAttrs then fnOrAttrs finalAttrs else fnOrAttrs;
          in orig // rec {
            version = "1.19.0";
            src = prev.fetchFromGitHub {
              owner = "dapr";
              repo = "cli";
              rev = "v${version}";
              sha256 = "sha256-6c23u6PS8KwfkUr4nj6A2Q/jsRlGM0CzHdqKIodNQ+c=";
            };
            vendorHash = "sha256-P7zrfUcb/Hxo7QbIQfq9JSf2d7meZShQ++GG8HkEoLE=";
            ldflags = [
              "-X main.version=${version}"
              "-X main.apiVersion=1.0"
              "-X github.com/dapr/cli/pkg/standalone.gitcommit=${src.rev}"
              "-X github.com/dapr/cli/pkg/standalone.gitversion=${version}"
            ];
          };
      in prev.buildGo126Module wrapFn;
  };
}
