{ lib
, buildGo118Module
, fetchFromGitHub
, pkg-config
, libpulseaudio
, patches ? []
}:

let
  totalPatches = patches ++ [ ];
in

buildGo118Module rec {
  pname = "somestatus";
  version = "0.1.5";

  src = fetchFromGitHub {
    owner = "joshvanl";
    repo = pname;
    rev = "e7b48e367910063c95343a907afb2e1c5d951deb";
    hash = "sha256-STzRNl6Nk1Lt80xV1JdxrQ+6dfX9TjNY9pPAfPxu93I=";
  };

  vendorSha256 = "sha256-jIrWIURv8od7NVoNvV4S63sIQRHmT4NfKIbaifawWQw=";

  patches = totalPatches;

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    libpulseaudio
  ];

  meta = with lib; {
    homepage = "https://github.com/joshvanl/somestatus";
    description = "status bar information, implemented for somebar";
    longDescription = ''
      status bar information, implemented for somebar
      https://git.sr.ht/~raphi/somebar";
    '';
    license = licenses.asl20;
  };
}
