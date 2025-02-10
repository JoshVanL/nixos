final: prev: {
  backblaze-b2 = prev.backblaze-b2.overrideAttrs (oldAttrs: {
    nativeBuildInputs = with prev.python3Packages; prev.backblaze-b2.nativeBuildInputs ++ [
      setuptools
      (phx-class-registry.overridePythonAttrs (old: {
        version = "4.1.0";
        src = prev.fetchPypi {
          version = "4.1.0";
          pname = "phx-class-registry";
          sha256 = "sha256-an/oVo+QAK0fkMmoHFy2XsIO47ibKqq3pn4U27Z+EdE=";
        };

         nativeBuildInputs = [
         wrapPython
            setuptools
          ];
      }))
    ];
  });
}

