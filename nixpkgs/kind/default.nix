{ lib
, buildGo118Module
, fetchFromGitHub
}:

buildGo118Module rec {
  pname = "kind";
  version = "0.13.0";

  src = fetchFromGitHub {
    owner = "sigs.k8s.io";
    repo = pname;
    rev = "b33b60a1afd119c0516f5bd4a89763dba6d10c59";
    hash = "sha256-GrJ48q4RxvMHr3z7V37LLyuaok5VNGOq+HEhay+/gMA=";
  };

  vendorSha256 = "sha256-/UDmTyngydoso9F/iPp5JYlsfi0VNfHfTsxdGDaTK+w=";

  subPackages = [ "." ];

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
