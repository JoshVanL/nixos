{ lib
, buildGoModule
, fetchFromGitHub
, installShellFiles
}:

buildGoModule rec {
  pname = "mockery";
  version = "2.22.1";

  src = fetchFromGitHub {
    owner = "vektra";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-Jzb7JHzJbWwaSXoSR0wfCCs0r5vLEilTAm5oNHtj+pM=";
  };

  vendorSha256 = "sha256-w4DONTXbsAjJD5ytvBLR+sOIGEMWEUxEzs25UiQkGuw=";

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
