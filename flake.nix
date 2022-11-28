{ inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/22.05";

    flake-utils.url = "github:numtide/flake-utils/v1.0.0";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        compiler = "ghc922";

        config = { };

        overlay =  (import ./default.nix).overlay;

        overlays = [ overlay  ];

        pkgs = import nixpkgs { inherit config system overlays; };

      in
        rec {
          overlays.default = overlay;
          packages.default = pkgs.haskell.packages."${compiler}".ghc-nix;

          packages.self-test = pkgs.haskell.packages."${compiler}".callPackageIncrementally ./ghc-nix {};
          # This currently fails to compile ghc-nix
          # packages.self-test-902 = pkgs.haskell.packages.ghc902.callPackageIncrementally ./ghc-nix {};
          packages.self-test-924 = pkgs.haskell.packages.ghc924.callPackageIncrementally ./ghc-nix {};
          packages.other-test = pkgs.haskell.packages."${compiler}".withGhcNix pkgs.haskell.packages."${compiler}".fused-effects;
          # packages.other-test2 = lib.withGhcNix pkgs.haskell.packages."${compiler}".generics-eot;

          devShells.default = packages.default.env.overrideAttrs(oldAttrs : {
            buildInputs = [pkgs.cabal-install ] ++ oldAttrs.buildInputs;
          });

          apps.default = {
            type = "app";
            program = "${packages.default}/bin/ghc-nix";
          };

          defaultPackage = packages.default;

          defaultApp = apps.default;

          devShell = devShells.default;

     }
   );
}
