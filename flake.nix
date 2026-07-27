{
  description = "Arch + Nix (standalone Home Manager) + Niri dotfiles — Dell Latitude 7450";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # which-key-wayland (interactive key-hint panel) — packaged upstream as a
    # flake; overlay-exposed here so it installs like any nixpkgs package.
    # `follows` is safe: package.nix builds via rustPlatform (nixpkgs' bundled
    # rust), not the flake's fenix devShell toolchain.
    which-key-wayland.url = "github:liuhq/which-key.wayland?ref=refs/tags/0.2.1";
    which-key-wayland.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, which-key-wayland, ... }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        (final: prev: {
          which-key-wayland = which-key-wayland.packages.${system}.which-key-wayland;
        })
      ];
    };
  in {
    homeConfigurations."bobbytables" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ./home.nix
      ];
    };
  };
}
