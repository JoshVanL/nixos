{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "interfacebloat";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "sashamelentyev";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-GK7SUiVnOUF7uCqb9uxhII6g8Tr0G7GSLhj1rVjeQA8=";
  };

  vendorSha256 = "sha256-1UvF2TwH+av50dSUuLjy/KfIEIqDbtXeTGvd33RjP3A=";

  meta = with lib; {
    homepage = "https://github.com/sashamelentyev/interfacebloat";
    description = "A linter that checks the number of methods inside an interface.";
    longDescription = ''
      Interface bloat (anti-pattern, also called fat interface) is when an
      interface incorporates too many operations on some data.

      A linter that checks length of interface.

      The bigger the interface, the weaker the abstraction. (C) Go Proverbs
    '';
    license = licenses.mit;
  };
}
