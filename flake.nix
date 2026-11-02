{
    description = "Liner music client port to flake";
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        flake-utils.url = "github:numtide/flake-utils";

        liner = {
            url = "github:tryliner/desktop";
            flake = false;
        };
    };

    outputs = inputs@{ self, liner, flake-utils, nixpkgs, ...  }: inputs.flake-utils.lib.eachDefaultSystem(system: let
        pkgs = nixpkgs.legacyPackages.${system};
        packageDotJSON = builtins.fromJSON (builtins.readFile "${liner}/package.json");

        pname = packageDotJSON.desktopName;
        version = packageDotJSON.version;

        desktopItems = [ (pkgs.makeDesktopItem {
            name = pname;
            exec = pname;
            icon = pname;
            comment = "Liner Music Player";
            desktopName = "Liner";
            categories = [ "Audio" ];
        }) ];

        # Hashes
        src = liner;
        pnpmDeps = pkgs.fetchPnpmDeps {
            inherit pname version src pnpm;
            fetcherVersion = 3;
            hash = "sha256-7D34DBAqFGNFQ+AqKkK2FKsaZDKB3kbtfRR0BSq/tI4=";
        };

        # Build
        pnpm = pkgs.pnpm_10;
        nativeBuildInputs = with pkgs; [
            nodejs_22 pnpm
            (pnpmConfigHook.override {  inherit pnpm; })
            makeWrapper
            copyDesktopItems
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
                src pnpmDeps desktopItems
                nativeBuildInputs;

            buildPhase = ''
                runHook preBuild

                pnpm run build

                runHook postBuild
            '';
            installPhase = ''
                runHook preInstall

                # mkdir -p $out/test
                # cp -r * $out/test/

                mkdir -p $out/opt/liner
                cp -r dist dist-electron package.json $out/opt/liner/
                cp -r node_modules $out/opt/liner/

                mkdir -p $out/bin

                makeWrapper ${pkgs.electron_44}/bin/electron $out/bin/${pname} \
                    --add-flags "$out/opt/liner" \
                    --add-flags "--ozone-platform-hint=auto" \
                    --add-flags "--enable-features=WaylandWindowDecorations" \
                    --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath buildInputs}" \
                    --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"

                mkdir -p $out/share/icons/hicolor
                for size in 16x16 32x32 48x48 64x64 128x128 256x256 512x512; do
                    [ -f "build/icons/$size.png" ] && install -D build/icons/$size.png $out/share/icons/hicolor/$size/apps/${pname}.png
                done

                runHook postInstall
            '';
        };
    });
}
