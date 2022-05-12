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
  version = "0.1.6";

  src = fetchFromGitHub {
    owner = "joshvanl";
    repo = pname;
    rev = "61c058d41a359ec28cbbf19eb0d3a687810e8109";
    hash = "sha256-3nkx1UNXBCF6oET42g8pkdYkY8jSsyBAjs+ni77Y2jE=";
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
