{ lib, pkgs, applyPatches }:

pkgs.buildGo118Module rec {
  pname = "somestatus";
  version = "0.1.0";

  src = pkgs.fetchFromGitHub {
    owner = "joshvanl";
    repo = pname;
    rev = "dbd213e1ae2440c9372b3ab2999a5cf0f7b24b62";
    hash = "sha256-GFQhmHTBQt3C5Y062uGJ5IYMKhrUWwpvqvtAwTGLuJI=";
  };

  vendorSha256 = "sha256-jIrWIURv8od7NVoNvV4S63sIQRHmT4NfKIbaifawWQw=";

  nativeBuildInputs = [
    pkgs.pkg-config
  ];

  buildInputs = [
    pkgs.libpulseaudio
  ];

  meta = with lib; {
    homepage = "https://github.com/joshvanl/somestatus";
    description = "status bar information, implemented for somebar";
    longDescription = ''
      status bar information, implemented for somebar
      https://git.sr.ht/~raphi/somebar";
    '';
    license = licenses.asl20;
    inherit (pkgs.wayland.meta) platforms;
  };
}
