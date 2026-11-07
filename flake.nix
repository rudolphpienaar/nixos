{
  description = "Callisto and Vendian workstation configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    starship-config = {
      url = "github:rudolphpienaar/starship-config";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      starship-config,
      ...
    }:
    let
      mkHost =
        hostModule:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            hostModule
            home-manager.nixosModules.home-manager
            {
              home-manager.extraSpecialArgs = { inherit starship-config; };
            }
          ];
        };
    in
    {
      nixosConfigurations.callisto = mkHost ./configuration.nix;
      nixosConfigurations.vendian = mkHost ./hosts/vendian;
    };
}
