{ inputs
, lib
, callPackage
, python313
}:

# Dependency versions come from uv.lock. To change them, edit pyproject.toml
# and run `uv lock` here.
let
  workspace = inputs.uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };

  pythonSet = (callPackage inputs.pyproject-nix.build.packages {
    python = python313;
  }).overrideScope (lib.composeManyExtensions [
    inputs.pyproject-build-systems.overlays.wheel
    (workspace.mkPyprojectOverlay { sourcePreference = "wheel"; })
  ]);

in (pythonSet.mkVirtualEnv "catalyst-agents" workspace.deps.default).overrideAttrs {
  meta = {
    description = "Dapr Agents on Diagrid Catalyst that catalyst-cron calls: job-doctor and bump";
    mainProgram = "catalyst-agents";
  };
}
