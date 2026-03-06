final: prev: rec {
   dapr-cli = prev.dapr-cli.overrideAttrs (oldAttrs: rec {
    version = "1.17.1-rc.1";
    src = prev.fetchFromGitHub {
      owner = "dapr";
      repo = "cli";
      rev = "v${version}";
      sha256 = "sha256-Y+b4cXI1mLQ6YB3JlSIkvjNz2arOBZfv6EMJHHEqU0w=";
    };
    vendorHash = "sha256-o8lEcTTIASvhpRJveo0UciGhwSu+5z9+jQcII9+D5Z8=";

    ldflags = [
      "-X main.version=${version}"
      "-X main.apiVersion=1.0"
      "-X github.com/dapr/cli/pkg/standalone.gitcommit=${src.rev}"
      "-X github.com/dapr/cli/pkg/standalone.gitversion=${version}"
    ];
  });
}
