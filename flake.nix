{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    systems.url = "github:nix-systems/default";

    emacs-overlay.url = "github:nix-community/emacs-overlay";

    org-babel.url = "github:emacs-twist/org-babel";

    twist.url = "github:emacs-twist/twist.nix";

    lsp-proxy = {
      url = "github:jadestrong/lsp-proxy";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    elpa = {
      url = "github:elpa-mirrors/elpa";
      flake = false;
    };
    melpa = {
      url = "github:melpa/melpa";
      flake = false;
    };
    nongnu = {
      url = "github:elpa-mirrors/nongnu";
      flake = false;
    };
    epkgs = {
      url = "github:emacsmirror/epkgs";
      flake = false;
    };
  };

  outputs = inputs@{
    flake-parts,
    systems,
    emacs-overlay,
    org-babel,
    twist, 
    lsp-proxy,
    ...
  }: flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import systems;

      perSystem = { pkgs, system, ... }:
        let
          initFile = pkgs.tangleOrgBabelFile "init.el" ./init.org {};
          earlyInit = pkgs.tangleOrgBabelFile "early-init.el" ./early-init.org {};

          initDir = pkgs.linkFarm "emacs-init" [
            { name = "early-init.el"; path = earlyInit; }
            { name = "init.el"; path = initFile; }
	    { name = "languages.toml"; path = ./languages.toml; }
          ];

          launcher = pkgs.writeShellScript "emacs-launch" ''
            exec ${package}/bin/emacs --init-directory ${initDir} "$@"
          '';

          profile = {
            lockDir = ./lock;
            initFiles = [ initFile ];
            initParser = twist.lib.parseSetup { inherit (inputs.nixpkgs) lib; } { };
            extraPackages = [
              "setup"
            ];
            emacsPackage = pkgs.emacs-unstable-pgtk;
            extraRecipeDir = ./recipes;
            exportManifest = true;
          };

          package = (
            twist.lib.makeEnv {
            inherit pkgs;
            inherit (profile)
              emacsPackage
              lockDir
              initFiles
              initParser
              extraPackages
              exportManifest;
            registries = [
                {
                  name = "recipes";
                  type = "melpa";
                  path = profile.extraRecipeDir;
                }
              ] ++ (import ./registries.nix inputs);

            extraSiteStartElisp = ''
            (add-to-list 'treesit-extra-load-path "${treesitGrammars}/lib")
          ''; 
            }).overrideScope (_final: prev: {
	      executablePackages = prev.executablePackages ++ [
		pkgs.ripgrep
		lsp-proxy.packages.${system}.default
	      ];
	    });

          treesitGrammars = pkgs.emacsPackages.treesit-grammars.with-all-grammars;

        in {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;

          overlays = [
            emacs-overlay.overlay
            org-babel.overlays.default
          ];
        };

        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.nixd
          ];
        };

        packages.default = package;
        apps = (package.makeApps { lockDirName = "./lock"; }) // { default = { type = "app"; program = "${launcher}"; }; };
      };
  };
}
