{
  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    snakemake = {
      url = "git+ssh://git@gitlab.lan.evaxion-biotech.com/tools/dinky/snakemake.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #myLocalPkg = {
    #  url = "git+ssh://git@gitlab.lan.evaxion-biotech.com/tools/dinky/myLocalPkg.git";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    pythonOverrides = {
      packageOverrides = (
        final: prev:
        # Snakemake and dependencies
          ((inputs.snakemake.pythonOverrides.${system}.default final) prev)
          # Local dependencies from requirements.nix
          // ((pkgs.callPackage ../requirements.nix {inherit pkgs;} final) prev)
      );
    };
    python = pkgs.python310.override pythonOverrides;
    pythonEnv = python.withPackages (ps:
      with ps; [
        numpy
        polars
        matplotlib
        #
        ipykernel
        nbconvert
        snakemake
        # exp{{ cookiecutter.exp }} # Located in lib/
        # Add packages from requirements.nix
        #mhcgnomes
      ]);
    deps = [
      # Add non-python packages here
      #pkgs.globalpkg (from nixpkgs)
      #inputs.myLocalPkg.packages.${system}.default
    ];
  in {
    apps.${system} = {
      sm-evx = let
        smProfile = inputs.snakemake.packages.${system}.smProfileEvx;
      in {
        type = "app";
        program = toString (pkgs.writers.writeBash "sm-evx" ''
          export PATH=${pkgs.lib.makeBinPath deps}:$PATH
          ${pythonEnv}/bin/python -m snakemake --profile ${smProfile} "$@"
        '');
      };

      install-jupyter-kernel = {
        type = "app";
        program = toString (pkgs.writers.writeBash "install-jupyter-kernel" ''
          ${pythonEnv}/bin/python -m ipykernel install --user --name exp{{ cookiecutter.exp }}_010 --display-name "Python (exp{{ cookiecutter.exp }}_010)" \
        '');
      };
    };

    devShells.${system} = {
      default = pkgs.mkShell {
        buildInputs = deps ++ [pythonEnv];
      };
    };
  };
}
