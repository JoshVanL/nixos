{ lib
, buildGo118Module
, fetchFromGitHub
, installShellFiles
}:

buildGo118Module rec {
  pname = "cmctl";
  version = "1.9.1";

  src = fetchFromGitHub {
    owner = "cert-manager";
    repo = "cert-manager";
    rev = "v${version}";
    hash = "sha256-Z1aJ18X4mfJPlCPBC7QgfdX5Tk4+PK8mYoJZhGwz9ec=";
  };

  vendorSha256 = "sha256-45+tZZAEHaLdTN1NQCueJVTx5x2IanwDl+Y9MELqdBE=";
  subPackages = [ "cmd/ctl" ];

  ldflags = [
    "-w" "-s"
    # See https://github.com/cert-manager/cert-manager/blob/4486c01f726f17d2790a8a563ae6bc6e98465505/make/cmctl.mk#L1
    "-X" "github.com/cert-manager/cert-manager/cmd/ctl/pkg/build.name=cmctl"
    "-X" "github.com/cert-manager/cert-manager/cmd/ctl/pkg/build/commands.registerCompletion=true"
  ];

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    mv $out/bin/ctl $out/bin/cmctl
    $out/bin/cmctl completion bash > cmctl.bash
    $out/bin/cmctl completion zsh  > cmctl.zsh
    $out/bin/cmctl completion fish > cmctl.fish
    installShellCompletion cmctl.{bash,zsh,fish}
  '';

  meta = with lib; {
    homepage = "cert-manager.io";
    description = "Automatically provision and manage TLS certificates in Kubernetes.";
    longDescription = ''
      cert-manager adds certificates and certificate issuers as resource types
      in Kubernetes clusters, and simplifies the process of obtaining, renewing
      and using those certificates.

      It can issue certificates from a variety of supported sources, including
      Let's Encrypt, HashiCorp Vault, and Venafi as well as private PKI, and it
      ensures certificates remain valid and up to date, attempting to renew
      certificates at an appropriate time before expiry.
    '';
    license = licenses.asl20;
  };
}
