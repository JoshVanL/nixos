{
  inputs = {
    #jnixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs.url = "nixpkgs/nixos-25.05";
    home-manager = {
      #url = "github:nix-community/home-manager";
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    joshvanldwm = {
      url = "github:joshvanl/dwm?rev=d084abaa0a508f7a016cd7becc74e7e0523a3e23";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-serve-ng = {
      url = "github:aristanetworks/nix-serve-ng";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    xpropdate = {
      url = "github:joshvanl/xpropdate";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur.url = github:nix-community/nur;
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    modules = import ./modules {inherit self nixpkgs inputs; };
  in modules;
}
