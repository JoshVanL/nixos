{ lib, pkgs, applyPatches }:

pkgs.buildGo118Module rec {
  pname = "somestatus";
  version = "0.1.1";

  src = pkgs.fetchFromGitHub {
    owner = "joshvanl";
    repo = pname;
    rev = "40b29555815185d2ac875237770ee6e66b54f73e";
    hash = "sha256-Lwc+oFsLhjrt2tCGLnXlRch1hznovntFkKJMRUV7+3M=";
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
