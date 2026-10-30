{
    description = "Liner music client port to flake";
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    outputs = inputs@{ self, nixpkgs,...  }:let
        supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
        forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in {
        devShells = forAllSystems(system: let
                pkgs = import nixpkgs { inherit system; };
        in {
            default = pkgs.mkShell {
                shellHook = ''
                echo Hii
                '';
            };
        });
    };
}
