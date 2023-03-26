{ pkgs, ... }:
with pkgs;
{
  go-jwt = callPackage ./go-jwt {};
  gomarkdoc = callPackage ./gomarkdoc {};
  go-protobuf = callPackage ./go-protobuf {};
  go-protobuf-grpc = callPackage ./go-protobuf-grpc {};
  helm = callPackage ./helm {};
  kind = callPackage ./kind {};
  paranoia = callPackage ./paranoia {};
  vcert = callPackage ./vcert {};
  gke-gcloud-auth-plugin = callPackage ./gke-gcloud-auth-plugin {};
  zfs_uploader = callPackage ./zfs_uploader {
    python3 = python3;
    python3Packages = python3Packages;
  };
  mockery = callPackage ./mockery {};
  interfacebloat = callPackage ./interfacebloat {};
  dupword = callPackage ./dupword {};
  shadow-go = callPackage ./shadow {};
}