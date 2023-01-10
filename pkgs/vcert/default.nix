{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "vcert";
  version = "4.22.1";

  src = fetchFromGitHub {
    owner = "Venafi";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-m0EGkSfVqJtroyWGXEgAnrwiicSSz+bFDWJL28QjY4c=";
  };

  vendorSha256 = "sha256-xRcEaCo7Y+GOTAAuynrrsGx5bI+qGbfoAWIwRxS22Y0=";
  doCheck = false;

  meta = with lib; {
    homepage = "https://www.venafi.com";
    description = " Go client SDK and command line utility designed to simplify integrations by automating key generation and certificate enrollment using Venafi machine identity services.";
    longDescription = ''
      VCert is a Go library, SDK, and command line utility designed to simplify
      key generation and enrollment of machine identities (also known as
      SSL/TLS certificates and keys) that comply with enterprise security
      policy by using the Venafi Trust Protection Platform or Venafi as a
      Service.
    '';
    license = licenses.asl20;
  };
}
