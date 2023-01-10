{ lib
, buildGoModule
, fetchFromGitHub
, installShellFiles
}:

buildGoModule rec {
  pname = "gomarkdoc";
  version = "0.4.1";

  src = fetchFromGitHub {
    owner = "princjef";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-ep1dVsKKydqeQjz5ocZ8tQeJfCb66Oy36FPh/juLUgA=";
  };

  vendorSha256 = "sha256-LfovwcipO3/ovHLDSLRhHcEocbKdW399o6mJ45GavBM=";
  subPackages = [ "cmd/gomarkdoc" ];

  nativeBuildInputs = [ installShellFiles ];
  postInstall = ''
    installShellCompletion --cmd gomarkdoc \
      --bash <($out/bin/gomarkdoc completion bash) \
      --fish <($out/bin/gomarkdoc completion fish) \
      --zsh <($out/bin/gomarkdoc completion zsh)
  '';

  meta = with lib; {
    homepage = "https://github.com/princjef/gomarkdoc";
    description = " Generate markdown documentation for Go (golang) code";
    longDescription = ''
      Package gomarkdoc formats documentation for one or more packages as
      markdown for usage outside of the main https://pkg.go.dev site. It
      supports custom templates for tweaking representation of documentation at
      fine-grained levels, exporting both exported and unexported symbols, and
      custom formatters for different backends.
    '';
    license = licenses.mit;
  };
}
