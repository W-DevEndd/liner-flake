{
    description = "Liner music client port to flake";
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        flake-utils.url = "github:numtide/flake-utils";
    };

    outputs = inputs@{ self, flake-utils, nixpkgs, ...  }: inputs.flake-utils.lib.eachDefaultSystem(system: let
        pkgs = nixpkgs.legacyPackages.${system};

        owner = "tryliner";
        repo = "desktop";
        pname = "liner";
        version = "0.2.10";

        # Hashes
        src = pkgs.fetchFromGitHub {
            inherit owner repo;
            rev = "v${version}";
            hash = "sha256-Utv76NXnlm2W43Yn4i7wq0859z5w8D6gX3vsQQ9E06w=";
        };
        pnpmDeps = pkgs.fetchPnpmDeps {
            inherit pname version src pnpm;
            fetcherVersion = 3;
            hash = "sha256-Lhf49YsFL/cU+abowJthzxNrIaJIiW8K+EwaNZjzq8w=";
        };

        # Build
        pnpm = pkgs.pnpm_10;
        nativeBuildInputs = with pkgs; [
            nodejs_22 pnpm
            (pnpmConfigHook.override {  inherit pnpm; })
        ];
        buildInputs = with pkgs; [
            atk cups dbus cairo gtk3 pango
            libx11 libxcomposite libxdamage libxext libxfixes libxrandr
            libgbm expat libxcb libxkbcommon udev alsa-lib
            stdenv.cc.cc.lib
            nspr nss glib libGL
        ];
    in {
        packages.default = pkgs.stdenv.mkDerivation rec {
            inherit
                pname version
                src pnpmDeps
                nativeBuildInputs;


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
    });
}
