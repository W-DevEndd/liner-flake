{
    description = "Liner music client port to flake";
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    outputs = inputs@{ self, nixpkgs, ...  }: let
        owner = "tryliner";
        repo = "desktop";
        pname = "liner";
        version = "0.2.10";

        supportedSystems = [ "x86_64-linux" ];
        forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in {
        packages = forAllSystems(system: let
            pkgs = import nixpkgs { inherit system; };
            pnpm =pkgs.pnpm_10;

            src = pkgs.fetchFromGitHub {
                inherit owner repo;
                rev = "v${version}";
                hash = "sha256-Utv76NXnlm2W43Yn4i7wq0859z5w8D6gX3vsQQ9E06w=";
            };
            deps = pkgs.fetchPnpmDeps {
                inherit pname version src pnpm;
                fetcherVersion = 3;
                hash = "sha256-Lhf49YsFL/cU+abowJthzxNrIaJIiW8K+EwaNZjzq8w=";
            };

            buildInputs = with pkgs; [
                atk cups dbus cairo gtk3 pango
                libx11 libxcomposite libxdamage libxext libxfixes libxrandr
                libgbm expat libxcb libxkbcommon udev alsa-lib
                stdenv.cc.cc.lib
                nspr nss glib libGL
            ];
        in {
            liner = pkgs.stdenv.mkDerivation rec {
                inherit pname version src;

                pnpmDeps = deps;

                nativeBuildInputs = with pkgs; [
                    nodejs_22
                    pnpm
                    (pnpmConfigHook.override {  inherit pnpm; })
                    # autoPatchelfHook
                    # makeWrapper
                ];
                inherit buildInputs;

                buildPhase = ''
                    runHook preBuild

                    pnpm run build

                    runHook postBuild
                '';
                installPhase = ''
                    mkdir -p $out
                    cp * -r $out
                '';
            };
            default = self.packages.${system}.liner;
        });

        devShells = forAllSystems(system: let
            pkgs = import nixpkgs { inherit system; };
        in {
            default = pkgs.mkShell {
                shellHook = ''
                echo Hii
                echo ${system}
                '';
            };
        });
    };
}
