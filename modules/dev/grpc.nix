{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.dev.grpc;

in {
  options.me.dev.grpc = {
    enable = mkEnableOption "dev.grpc";
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d /keep/home/go 0755 ${config.me.base.username} wheel - -"
      "L+ /home/${config.me.base.username}/go - - - - /keep/home/go"
    ];
    home-manager.users.${config.me.base.username}.home = {
      packages = with pkgs; [
        grpcurl
        protobuf
      ] ++ (optionals config.me.dev.go.enable [
        go-protobuf
        go-protobuf-grpc
      ]);
    };
  };
}
