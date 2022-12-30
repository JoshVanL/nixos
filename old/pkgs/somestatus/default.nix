{ lib
, buildGo119Module
, fetchFromGitHub
, pkg-config
, libpulseaudio
, patches ? []
}:

let
  totalPatches = patches ++ [ ];
in

buildGo119Module rec {
  pname = "somestatus";
  version = "0.1.7";

  src = fetchFromGitHub {
    owner = "joshvanl";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-VO9OtmEnRkaPthzA5JV6yseUmMRrgD2lnMVnFWK9GVM=";
  };

  vendorSha256 = "sha256-NvUfL0fsT28j8EDu+ub7wnezQVSBRKrDfW8sq6XnOy8=";

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
