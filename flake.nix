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
        sha256 = "sha256-ndGT93KwGm3RxcU3NbZjELYUg48opsgmM+FD7R7kM0Q=";

        supportedSystems = [ "x86_64-linux" ];
        forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in {
        packages = forAllSystems(system: let
            pkgs = import nixpkgs { inherit system; };

            latestYml = pkgs.fetchurl {
                url = "https://github.com/${owner}/${repo}/releases/download/v${version}/latest-linux.yml";
                sha256 = sha256;
            };
            metadata = builtins.fromJSON (builtins.readFile (pkgs.runCommand "parse-yaml" { nativeBuildInputs = [ pkgs.yq ]; } ''
            yq . ${latestYml} > $out
            ''));

            debInfo = builtins.head (builtins.filter (f: pkgs.lib.hasSuffix "_amd64.deb" f.url) metadata.files);

            buildInputs = with pkgs; [
                atk cups dbus cairo gtk3 pango
                libx11 libxcomposite libxdamage libxext libxfixes libxrandr
                libgbm expat libxcb libxkbcommon udev alsa-lib
                stdenv.cc.cc.lib
                nspr nss glib libGL
            ];
        in {
            liner = pkgs.stdenv.mkDerivation {
                inherit pname version;

                src = pkgs.fetchurl {
                    url = "https://github.com/${owner}/${repo}/releases/download/v${version}/${debInfo.url}";
                    hash = "sha512-${debInfo.sha512}";
                };

                nativeBuildInputs = with pkgs; [ dpkg autoPatchelfHook makeWrapper ];
                inherit buildInputs;

                installPhase = ''
                mkdir -p $out/bin
                cp -r * $out

                makeWrapper $out/opt/Liner/liner $out/bin/${pname} \
                    --argv0 "${pname}" \
                    --add-flags "--ozone-platform-hint=auto" \
                    --add-flags "--enable-features=UseOzonePlatform" \
                    --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath buildInputs}" \
                    --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
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
