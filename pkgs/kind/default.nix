{ lib
, buildGo119Module
, fetchFromGitHub
}:

buildGo119Module rec {
  pname = "kind";
  version = "0.14.0";

  src = fetchFromGitHub {
    owner = "kubernetes-sigs";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-yCzznSVWuVEkaoj9bo0WOp3Dvl3t1UJ/DwtXv5dp+dQ=";
  };

  vendorSha256 = "sha256-/UDmTyngydoso9F/iPp5JYlsfi0VNfHfTsxdGDaTK+w=";
  subPackages = [ "." ];

  postInstall = ''
    mkdir -p $out/share/{bash-completion/completions,zsh/site-functions}
    $out/bin/kind completion bash > $out/share/bash-completion/completions/kind
    $out/bin/kind completion zsh > $out/share/zsh/site-functions/_kind
  '';

  meta = with lib; {
    homepage = "https://github.com/kubernetes-sigs/kind";
    description = "Kubernetes IN Docker - local clusters for testing Kubernetes";
    longDescription = ''
      kind is a tool for running local Kubernetes clusters using Docker
      container "nodes". kind was primarily designed for testing Kubernetes
      itself, but may be used for local development or CI.
    '';
    license = licenses.asl20;
  };
}
