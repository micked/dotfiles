{
  inputs.nixpkgs.url = "nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      # System types to support.
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          {{package}} = pkgs.stdenv.mkDerivation rec {
            pname = "{{package}}";
            version = "{{version}}";

            src = pkgs.fetchFromGitHub {
              owner = "...";
              repo = "...";
              rev = "...";
              sha256 = "sha256-0000000000000000000000000000000000000000000=";
            };

            #nativeBuildInputs = with pkgs; [ ];
            #buildInputs = with pkgs; [ ];
            #configurePhase = "";
            #buildPhase = "";
            #installPhase = "";
          };
        in
        {
          default = {{package}};
          docker = pkgs.dockerTools.buildLayeredImage {
            name = "{{package}}";
            tag = "built";
            created = builtins.substring 0 8 self.lastModifiedDate;
            contents = [ {{package}} pkgs.bash pkgs.coreutils ];
            config = {};
          };
        }
      );
    };
}

