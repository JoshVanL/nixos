{ lib, pkgs, applyPatches }:

pkgs.buildGo118Module rec {
  pname = "somestatus";
  version = "0.1.2";

  src = pkgs.fetchFromGitHub {
    owner = "joshvanl";
    repo = pname;
    rev = "cfb1c55a71d6155a1c63630fb36acf9babd7171f";
    hash = "sha256-4nbmPqdtGTWbiqIT7sTR9/SZeuEhYakQV8lm7Mt86eM=";
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
