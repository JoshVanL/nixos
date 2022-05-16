{ lib
, buildGo118Module
, fetchFromGitHub
}:

buildGo118Module rec {
  pname = "cmctl";
  version = "1.8.0";

  src = fetchFromGitHub {
    owner = "cert-manager";
    repo = "cert-manager";
    rev = "v${version}";
    hash = "sha256-h7GyzjVrfyMHY7yuNmmsym6KGKCQr5R71gjPBTUeMCg=";
  };

  vendorSha256 = "sha256-UYw9WdQ6VwzuuiOsa1yovkLZG7NmLYSW51p8UhmQMeI=";
  subPackages = [ "cmd/ctl" ];

  ldflags = [
    "-w" "-s"
    "-X" "github.com/cert-manager/cert-manager/cmd/ctl/pkg/build.name=cmctl"
    "-X" "github.com/cert-manager/cert-manager/cmd/ctl/pkg/build/commands.registerCompletion=true"
  ];

  postInstall = ''
    mv $out/bin/ctl $out/bin/cmctl
    mkdir -p $out/share/{bash-completion/completions,zsh/site-functions}
    $out/bin/cmctl completion bash > $out/share/bash-completion/completions/cmctl
    $out/bin/cmctl completion zsh > $out/share/zsh/site-functions/_cmctl
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
