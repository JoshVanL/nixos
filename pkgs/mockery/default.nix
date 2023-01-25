{ lib
, buildGoModule
, fetchFromGitHub
, installShellFiles
}:

buildGoModule rec {
  pname = "mockery";
  version = "2.16.0";

  src = fetchFromGitHub {
    owner = "vektra";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-fd+ZR74tApbZEXfMqpUAMk22h9rMRmtByGSd8JcTtK0=";
  };

  vendorSha256 = "sha256-SRTxe3y+wQgxsj7ruquMG16dUEAa92rnTXceysWm+F8=";

  nativeBuildInputs = [ installShellFiles ];
  postInstall = ''
    installShellCompletion --cmd mockery \
      --bash <($out/bin/mockery completion bash) \
      --fish <($out/bin/mockery completion fish) \
      --zsh <($out/bin/mockery completion zsh)
  '';

  meta = with lib; {
    homepage = "https://github.com/vektra/mockery";
    description = "A mock code autogenerator for Golang";
    longDescription = ''
      mockery provides the ability to easily generate mocks for Golang
      interfaces using the stretchr/testify/mock package. It removes the
      boilerplate coding required to use mocks.
    '';
    license = licenses.bsd3;
  };
}
