{ lib
, buildGo119Module
, fetchFromGitHub
}:

buildGo119Module rec {
  pname = "helm";
  version = "3.8.2";

  src = fetchFromGitHub {
    owner = "helm";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-lFAzp7ZxyMZAEO1cNFkEPLgTLEGa6azv36xiTIz4FZY=";
  };

  vendorSha256 = "sha256-FLEydmR+UEZ80VYLxBU1ZdwpdLgTjUpqiMItnt9UuLY=";
  subPackages = [ "cmd/helm" ];
  doCheck = false;

  postInstall = ''
    mkdir -p $out/share/{bash-completion/completions,zsh/site-functions}
    $out/bin/helm completion bash > $out/share/bash-completion/completions/helm
    $out/bin/helm completion zsh > $out/share/zsh/site-functions/_helm
  '';

  meta = with lib; {
    homepage = "https://github.com/helm/helm";
    description = "The Kubernetes Package Manager";
    longDescription = ''
      Helm is a tool for managing Charts. Charts are packages of pre-configured
      Kubernetes resources.
    '';
    license = licenses.asl20;
  };
}
