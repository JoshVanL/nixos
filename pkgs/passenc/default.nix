{
stdenv,
writeShellApplication,
installShellFiles,
openssl,
}:

with builtins;
let

  iterations = "1000000";
  minPassLength = "20";

  enc = writeShellApplication rec {
    name = "passenc";
    runtimeEnv = {
      PASSENC_MIN_PASS_LENGTH = "${minPassLength}";
      PASSENC_ITERATIONS = "${iterations}";
      PASSENC_HELP_TEXT="Password encrypt a file using AES-256-CBC with 1,000,000 rounds of PBKDF2.\nUse dpassenc to decrypt the file.";
      PASSENC_ACTION="encrypt";
      PASSENC_OTHER_CMD_NAME="passdenc";
    };
    runtimeInputs = [ openssl ];
    text = readFile ./passenc.sh;
  };


  denc = writeShellApplication rec {
    name = "passdenc";
    runtimeEnv = {
      PASSENC_MIN_PASS_LENGTH = "${minPassLength}";
      PASSENC_ITERATIONS = "${iterations}";
      PASSENC_HELP_TEXT="Decrypts the passenc encrypted file to the output file.";
      PASSENC_ACTION="decrypt";
      PASSENC_OTHER_CMD_NAME="passenc";
      PASSENC_EXTRA_FLAGS="-d";
    };
    runtimeInputs = [ openssl ];
    text = readFile ./passenc.sh;
  };

  sh = stdenv.mkDerivation {
    name = "passenc";
    srcs = [ enc denc ];
    sourceRoot = ".";
    nativeBuildInputs = [ installShellFiles ];
    installPhase = ''
      mkdir -p $out
      cp -r passenc/* passdenc/* $out
      installShellCompletion --cmd passenc
      installShellCompletion --cmd passdenc
    '';
  };

in sh
