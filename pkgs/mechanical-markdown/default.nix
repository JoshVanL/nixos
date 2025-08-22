{ lib
, pkgs
}:

with pkgs.python3Packages;

buildPythonPackage rec {
  pname = "mechanical-markdown";
  version = "0.7.0";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-R9dQzuFqo2WGXd+lLIf2qrr4xwxf9LdLyPQnVKB1gN4=";
  };

  propagatedBuildInputs = [
    requests
    mistune
    pyyaml
    termcolor
    colorama
  ];

  doCheck = false;
  pyproject = true;
  build-system = [ setuptools ];

  meta = with lib; {
    homepage = "https://github.com/dapr/mechanical-markdown";
    description = "Run annotated markdown tutorials in an automated fashion";
    longDescription = ''
      If you are using markdown to create tutorials for your users, these
      markdown files will often be a series of shell commands that a user will
      copy and paste into their shell of choice, along with detailed text
      description of what each command is doing.

      If you are regularly releasing software and having to manually verify
      your tutorials by copy pasting commands into a terminal every time you
      create a release, this is the package for you.

      The mechanical-markdown package is a Python library and corresponding
      shell script that allow you to run annotated markdown tutorials in an
      automated fashion. It will execute your markdown tutorials and verify the
      output according to expected stdout/stderr that you can embed directly
      into your markdown tutorials.
    '';
    license = licenses.asl20;
  };
}
