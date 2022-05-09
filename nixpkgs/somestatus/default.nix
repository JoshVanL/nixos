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
  version = "0.1.4";

  src = fetchFromGitHub {
    owner = "joshvanl";
    repo = pname;
    rev = "8e305144bd218bba44d362bddab6bf68b7992a66";
    hash = "sha256-PY0bcT1Fa+Cry8OqY6Ln1Jn6vgC+P9AgyyjySHvjyJA=";
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
