{ lib
, buildGoModule
, fetchFromGitHub
, installShellFiles
}:

buildGoModule rec {
  pname = "kind";
  version = "0.17.0";

  src = fetchFromGitHub {
    owner = "kubernetes-sigs";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-YAa5Dr8Pc6P3RZ3SCiyi7zwmVd5tPalM88R8bxgg6JU=";
  };

  vendorSha256 = "sha256-J/sJd2LLMBr53Z3sGrWgnWA8Ry+XqqfCEObqFyUD96g=";
  subPackages = [ "." ];

  nativeBuildInputs = [ installShellFiles ];
  postInstall = ''
    installShellCompletion --cmd kind \
      --bash <($out/bin/kind completion bash) \
      --fish <($out/bin/kind completion fish) \
      --zsh <($out/bin/kind completion zsh)
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
