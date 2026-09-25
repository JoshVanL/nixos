{ buildGoModule
, go_1_26
, lib
}:

(buildGoModule.override { go = go_1_26; }) {
  pname = "catalyst-cron";
  version = "0.1.0";

  src = ./.;
  vendorHash = "sha256-Lj+fCaa7M4Ps/HE3IhMwvn6HV39UqbVh2g0y0pztfXA=";

  meta = with lib; {
    description = "Run systemd units on a cron schedule using Dapr workflows on Diagrid Catalyst";
    mainProgram = "catalyst-cron";
  };
}
