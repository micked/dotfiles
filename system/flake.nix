{
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }: {
    nixosConfigurations.principle = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./configuration-desktop.nix ];
    };

    nixosConfigurations.burger = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./configuration-laptop.nix ];
    };

  };
}
