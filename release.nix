{
  nixpkgs ? import <nixpkgs> {}
, haskellCompiler ? "ghc7103"
, pythonCompiler ? "python34"
}:

let
  inherit (nixpkgs) stdenv pkgs;

  pythonOverrides =
    {
      overrides = self: super:
        {
          nbstripout = super.buildPythonPackage rec {
            version = "0.2.6";
            name = "nbstripout-${version}";
            src = pkgs.fetchurl {
              url = "https://pypi.python.org/packages/source/n/nbstripout/${name}.tar.gz";
              sha256 = "1dxij31pxl1lw1zcpi7s84g3ghnjvwamqp22hcr0vg7riwrr0a8w";
            };

            # TODO: what should build inputs look like?
            buildInputs = with self; [ /*pytest*/ /*nbformat*/ /*jupyter*/ setuptools ];
            propagatedBuildInputs = with self; [  ];
            doCheck = false;

            meta =
              {
                description = "strip output from Jupyter and IPython notebooks";
                homepage = "https://github.com/kynan/nbstripout";
                licenses = pkgs.licenses.mit;
                maintainers = [ ];
              };
          };
        };
    };
  pythonPackages = pkgs.${pythonCompiler + "Packages"} // pythonOverrides.overrides pythonPackages pkgs.${pythonCompiler + "Packages"};

  # It appears to be necessary to use python.buildEnv instead of pkgs.buildEnv in order to maintain the correct PYTHONPATH
  ipython-env = pythonPackages.python.buildEnv.override
                  {
                    extraLibs =
                      with pythonPackages;
                      [
                        notebook

                        # Python packages (comment/uncomment as needed)
                        ipywidgets
                        /* scipy */
                        /* toolz */
                        /* numpy */
                        /* matplotlib */
                        /* networkx */
                        /* pandas */
                        /* seaborn */

                        # Utilities (notebook formatting, cleaning for git etc)
                        nbstripout  # use this with .gitattributes for clean git commits
                      ];
                  };

  filterDist = src:
    let f = name: type: !(type == "directory" && baseNameOf (toString name) == "dist");
    in builtins.filterSource f src;

  haskellOverrides =
    {
      overrides = self: super:
        let
          callLocalPackage = path: self.callPackage (filterDist path) {};
          ihaskellSrc = pkgs.fetchFromGitHub
            {
              owner = "gibiansky";
              repo = "IHaskell";
              sha256 = "17987xf4vai18b0yjqqnk0km5mdp1pmcn4mpwlar757jrzwnjb6m";
              rev = "94338f8d4f6ee01c948c56b31ddb76fe8af0d630";
            };
          overrideIHaskellDisplaySrc = superPkg: pkgs.haskell.lib.overrideCabal superPkg (drv: drv //
            { src = ihaskellSrc;
              preUnpack = "sourceRoot=IHaskell-${ihaskellSrc.rev}-src/ihaskell-display/${superPkg.pname}";
            });
        in
          {
            # Overrides Latest version of ihaskell on GitHub
            /* ihaskell = pkgs.haskell.lib.overrideCabal super.ihaskell (drv: drv // { src = ihaskellSrc; }); */
            /* ihaskell-aeson = overrideIHaskellDisplaySrc super.ihaskell-aeson; */
            /* ihaskell-blaze = overrideIHaskellDisplaySrc super.ihaskell-blaze; */
            /* ihaskell-charts = overrideIHaskellDisplaySrc super.ihaskell-charts; */
            /* ihaskell-diagrams = overrideIHaskellDisplaySrc super.ihaskell-diagrams; */
            /* ihaskell-gnuplot = overrideIHaskellDisplaySrc super.ihaskell-diagrams; */
            /* ihaskell-hatex = overrideIHaskellDisplaySrc super.ihaskell-hatex; */
            /* ihaskell-juicypixels = overrideIHaskellDisplaySrc super.ihaskell-juicypixels; */
            /* ihaskell-magic = overrideIHaskellDisplaySrc super.ihaskell-magic; */
            /* ihaskell-plot = overrideIHaskellDisplaySrc super.ihaskell-plot; */
            /* ihaskell-rlangqq = overrideIHaskellDisplaySrc super.ihaskell-rlangqq; */
            /* ihaskell-static-canvas = overrideIHaskellDisplaySrc super.ihaskell-static-canvas; */
            /* ihaskell-widgets = pkgs.haskell.lib.dontHaddock (overrideIHaskellDisplaySrc super.ihaskell-widgets); */

            # Overrides for bleeding-edge ghc 8.0.x (Unfortunately this does not work yet)
            /* monads-tf = pkgs.haskell.lib.doJailbreak super.monads-tf; */
            /* ihaskell = */
            /*   self.callPackage */
            /*   ({ mkDerivation, aeson, base, base64-bytestring # , bin-package-db */
            /*    , bytestring, cereal, cmdargs, containers, directory, filepath, ghc */
            /*    , ghc-parser, ghc-paths, haskeline, haskell-src-exts, hlint, hspec */
            /*    , http-client, http-client-tls, HUnit, sa-kernel, mtl, parsec */
            /*    , process, random, setenv, shelly, split, stm, strict, system-argv0 */
            /*    , text, transformers, unix, unordered-containers, utf8-string, uuid */
            /*    , vector */
            /*    }: */
            /*    mkDerivation { */
            /*      pname = "ihaskell"; */
            /*      version = "0.8.3.0"; */
            /*      sha256 = "c486e0b6342fa6261c671ad6a891f5763f7979bc225781329fe9f913a3833107"; */
            /*      revision = "1"; */
            /*      editedCabalFile = "4079263fe3b633e589775753fe7e3bbab21c800fd7d54c2aa6761478c5019654"; */
            /*      isLibrary = true; */
            /*      isExecutable = true; */
            /*      libraryHaskellDepends = [ */
            /*        aeson base base64-bytestring /*bin-package-db* / bytestring cereal */
            /*        cmdargs containers directory filepath ghc ghc-parser ghc-paths */
            /*        haskeline haskell-src-exts hlint http-client http-client-tls */
            /*        sa-kernel mtl parsec process random shelly split stm strict */
            /*        system-argv0 text transformers unix unordered-containers */
            /*        utf8-string uuid vector */
            /*      ]; */
            /*      ds = [ */
            /*        aeson base /*bin-package-db* / bytestring containers directory ghc */
            /*        sa-kernel process strict text transformers unix */
            /*      ]; */
            /*      testHaskellDepends = [ */
            /*        aeson base base64-bytestring /*bin-package-db* / bytestring cereal */
            /*        cmdargs containers directory filepath ghc ghc-parser ghc-paths */
            /*        haskeline haskell-src-exts hlint hspec http-client http-client-tls */
            /*        HUnit sad-kernel mtl parsec process random setenv shelly split */
            /*        stm strict system-argv0 text transformers unix unordered-containers */
            /*        utf8-string uuid vector */
            /*      ]; */
            /*      doCheck = false; */
            /*      homepage = "http://github.com/gibiansky/IHaskell"; */
            /*      description = "A Haskell backend kernel for the IPython project"; */
            /*      license = stdenv.lib.licenses.mit; */
            /*    }) {}; */
          };
    };
  haskellPackages = pkgs.haskell.packages.${haskellCompiler}.override haskellOverrides;
  ihaskellWithPackages = packages: haskellPackages.ghcWithPackages
    (
      self:
        with self;
        [
          ihaskell

          # IHaskell displayables (comment/uncomment as needed)
          /* ihaskell-display */
          ihaskell-aeson
          ihaskell-blaze
          ihaskell-charts
          ihaskell-diagrams
          /* ihaskell-hatex */
          /* ihaskell-juicypixels */
          /* ihaskell-magic */
          /* ihaskell-plot */
          /* ihaskell-rlangqq */
          /* ihaskell-static-canvas */
          /* ihaskell-widgets */

          # Haskell packages (comment/uncomment as needed)
          opaleye
          cassava
        ] ++ packages self
    );
  ihaskell-env =
    let
      drv = ihaskellWithPackages
              (
                self:
                  with self;
                  [
                    # Add your own haskell packages here...
                  ]
              );
    in
      pkgs.buildEnv
        {
          name = "ihaskell-env";
          paths = [ drv ];
        };

in

  {
    inherit pythonPackages haskellPackages;
    jupyter-env = pkgs.buildEnv
      {
        name = "jupyter-env";
        paths =
          [
            ipython-env
            ihaskell-env
          ];
      };
  }
