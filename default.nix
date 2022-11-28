let compiler = "ghc922";
    config = { };
    withGhcNix' = pkgs: compiler :
      let inherit (pkgs.lib) or makeSearchPath;
          ghc-nix = pkgs.haskell.packages."${compiler}".callCabal2nix "ghc-nix" ./ghc-nix {};
      in pkg : ( pkgs.haskell.lib.overrideCabal pkg
            ( drv:
              { configureFlags = [ "-v -w ${ghc-nix}/bin/ghc-nix" ];
                # TODO: cctools on darwins
                buildTools = (drv.buildTools or []) ++ [ pkgs.bash pkgs.which pkgs.nix pkgs.coreutils pkgs.jq pkgs.gnused pkgs.rsync ] ;
                buildFlags = (drv.buildFlags or []) ++ [ "-v" ];
                preConfigure =
                  # We add all the executables (markdown-unlit,
                  # hspec-discover, etc) we find in the relevant sections
                  # of the package to the PATH.
                let buildTools = (drv.libraryToolDepends or []) ++ (drv.testToolDepends or []);
                    buildToolsPath = makeSearchPath "bin" buildTools;

                in ''
                   export NIX_GHC_PATH="${buildToolsPath}:$NIX_GHC_PATH"
                '';
              }
            ) ).overrideAttrs ( oldAttrs: {
              requiredSystemFeatures = (oldAttrs.requiredSystemFeatures or []) ++ [ "recursive-nix" ];
              NIX_PATH = pkgs.path;
        });
        # We add a ghc-nix to each available ghc
        overlay = self: super: {
          haskell = super.haskell // {
            packages = super.haskell.packages // self.lib.mapAttrs'
            (compiler: compilerAttr:
              self.lib.nameValuePair
              "${compiler}" (super.haskell.packages."${compiler}".override (old: {
                overrides =
                  self.lib.composeManyExtensions
                    [(old.overrides or (_: _: { }))
                    (self': super': rec {
                      withGhcNix = withGhcNix' super compiler;
                      callPackageIncrementally = drv: args: withGhcNix (super'.callPackage drv args);
                    })
                    (self.haskell.lib.packageSourceOverrides {
                      ghc-nix = ./ghc-nix;
                    })
                    ];
              })
              ))
            super.haskell.packages
            ;
          };
        };
in
  {
    inherit overlay;
  }