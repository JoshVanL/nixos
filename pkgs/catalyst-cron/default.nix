{ buildGoModule
, go_1_26_latest
, installShellFiles
, lib
}:

(buildGoModule.override { go = go_1_26_latest; }) {
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
