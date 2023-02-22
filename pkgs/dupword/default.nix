{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "dupword";
  version = "0.0.9";

  src = fetchFromGitHub {
    owner = "Abirdcfly";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-77YcfetV1pv5S3tcgxQlgwVhs/GNkSowqMm/11LuntM=";
  };

  subPackages = [ "cmd/dupword" ];

  vendorSha256 = null;

  meta = with lib; {
    homepage = "https://github.com/Abirdcfly/dupword";
    description = "A linter that checks for duplicate words in the source code (usually miswritten)";
    longDescription = ''
      A linter that checks for duplicate words in the source code (usually
      miswritten)

      Examples in real code and related issues can be viewed in dupword#3
    '';
    license = licenses.mit;
  };
}
