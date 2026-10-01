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

          makeLauncher = emacsEnv: pkgs.writeShellScript "emacs" ''
            set -eu
            # Home Manager (or the caller) owns explicitly selected init directories.
            for arg in "$@"; do
              case "$arg" in
                --init-directory|--init-directory=*|-init-directory|-init-directory=*)
                  exec ${emacsEnv}/bin/emacs "$@"
                  ;;
                --) break ;;
              esac
            done
            emacs_init_directory="''${XDG_CONFIG_HOME:-$HOME/.config}/emacs-nix"
            ${pkgs.coreutils}/bin/mkdir -p "$emacs_init_directory"
            for file in early-init.el init.el languages.toml; do
              ${pkgs.coreutils}/bin/ln -sfn "${initDir}/$file" "$emacs_init_directory/$file"
            done
            exec ${emacsEnv}/bin/emacs --init-directory "$emacs_init_directory" "$@"
          '';

          launcher = makeLauncher package;

          # Retain the Twist scope consumed by its Home Manager module.
          configuredPackage = package.overrideScope (_final: prev: let
            scopeLauncher = makeLauncher prev.emacsWrapper;
          in {
            earlyInitFile = earlyInit;
            emacsWrapper = pkgs.symlinkJoin {
              name = "emacs";
              paths = [ prev.emacsWrapper ];
              postBuild = ''
                ln -sfn ${scopeLauncher} $out/bin/emacs
              '';
              passthru = {
                inherit (prev.emacsWrapper) elispManifestPath;
              };
              meta.mainProgram = "emacs";
            };
          });

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
            (defconst emacs-config-directory "${initDir}")
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

        packages.default = configuredPackage;
        apps = (package.makeApps { lockDirName = "./lock"; }) // { default = { type = "app"; program = "${launcher}"; }; };
      };
  };
}
