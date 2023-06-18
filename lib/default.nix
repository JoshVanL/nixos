{ lib }:
with lib;

let
  targetSystems = [ "x86_64-linux" "aarch64-linux" ];

  nixFiles = dir: listToAttrs (map
    (file: nameValuePair (removeSuffix ".nix" (baseNameOf file)) file)
    (attrNames (filterAttrs (name: type:
      (type == "regular") && (hasSuffix ".nix" name)
    ) (builtins.readDir dir)))
  );
  dirs = dir: attrNames (filterAttrs (name: type: type == "directory") (builtins.readDir dir));
  nixFilesNoDefault = dir: filterAttrs (name: _: name != "default") (nixFiles dir);
  nixFilesNoDefault' = dir: attrValues (nixFilesNoDefault dir);
  defaultImport = dir: map (name: "${dir}/${name}") ((nixFilesNoDefault' dir) ++ (dirs dir));

in lib // {
  inherit dirs nixFilesNoDefault defaultImport targetSystems;
}
