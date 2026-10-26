{ buildGoModule
, fetchurl
, go_1_26
, installShellFiles
, lib
}:

let
  # go.mod needs go >= 1.26.10, newer than nixpkgs' go_1_26. Drop this once
  # go_1_26 catches up.
  go = go_1_26.overrideAttrs (old: rec {
    version = "1.26.10";
    src = fetchurl {
      url = "https://go.dev/dl/go${version}.src.tar.gz";
      hash = "sha256-/WPog7ovK/ypPBZGsx6+9j4rHk0rMXyXidl2po2B828=";
    };
  });

in (buildGoModule.override { inherit go; }) {
  pname = "catalyst-cron";
  version = "0.1.0";

  src = ./.;
  vendorHash = "sha256-1RhiF4tUnNqWoRwJJ6P0jWG6FLGaoABJQnarfaefxGI=";

  nativeBuildInputs = [ installShellFiles ];
  postInstall = ''
    installShellCompletion --cmd catalyst-cron \
      --zsh <($out/bin/catalyst-cron completion zsh)
  '';

  meta = with lib; {
    description = "Run systemd units on a cron schedule using Dapr workflows on Diagrid Catalyst";
    mainProgram = "catalyst-cron";
  };
}
