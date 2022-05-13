{ lib
, buildGo118Module
, fetchFromGitHub
}:

buildGo118Module rec {
  pname = "helm";
  version = "3.8.2";

  src = fetchFromGitHub {
    owner = "helm";
    repo = pname;
    rev = "6e3701edea09e5d55a8ca2aae03a68917630e91b";
    hash = "sha256-lFAzp7ZxyMZAEO1cNFkEPLgTLEGa6azv36xiTIz4FZY=";
  };

  vendorSha256 = "sha256-FLEydmR+UEZ80VYLxBU1ZdwpdLgTjUpqiMItnt9UuLY=";

  subPackages = [ "cmd/helm" ];

  doCheck = false;

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
