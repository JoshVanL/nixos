{ lib
, buildGoModule
, fetchFromGitHub
, installShellFiles
}:

buildGoModule rec {
  pname = "paranoia";
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "jetstack";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-oHLy+Z77XVRnLCeFHxiifUuAC5e39jWgoPrcaC04KSc=";
  };

  vendorHash = "sha256-9FZrvURa5nHnTifdlC1YbN0SAtkjiHdwHyQvLoTPXiM=";
  doCheck = false;

  nativeBuildInputs = [ installShellFiles ];
  postInstall = ''
    installShellCompletion --cmd paranoia \
      --bash <($out/bin/paranoia completion bash) \
      --fish <($out/bin/paranoia completion fish) \
      --zsh <($out/bin/paranoia completion zsh)
  '';

  meta = with lib; {
    homepage = "https://github.com/jetstack/paranoia";
    description = "Inspect certificate authorities in container images";
    longDescription = ''
      Who do you trust?

      Paranoia is a tool to analyse and export trust bundles (e.g.,
      "ca-certificates") from container images. These certificates identify the
      certificate authorities that your container trusts when establishing TLS
      connections. The design of TLS is that any certificate authority that
      your container trusts can issue a certificate for any domain. This means
      that a malicious or compromised certificate authority could issue a
      certificate to impersonate any other service, including your internal
      infrastructure.
    '';
    license = licenses.asl20;
  };
}
