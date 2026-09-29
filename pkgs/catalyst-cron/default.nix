{ buildGoModule
, go_1_26_4
, installShellFiles
, lib
}:

(buildGoModule.override { go = go_1_26_4; }) {
  pname = "catalyst-cron";
  version = "0.1.0";

  src = ./.;
  vendorHash = "sha256-tKj/vn6NYIG1Wcv75BNMYcRqHCZPd2Dum53O/LPGpYw=";

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
