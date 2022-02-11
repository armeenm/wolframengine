{
  description = "";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs;
    utils.url = github:numtide/flake-utils;
  };

  outputs = inputs@{ self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        name = "wolframengine";
        version = "13.0.0";

        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        lib = pkgs.lib;

      in rec {
        packages.${name} = pkgs.callPackage ./src {};
        defaultPackage = packages.${name};
      }
    );
}
