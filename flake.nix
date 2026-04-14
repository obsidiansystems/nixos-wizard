{
  description = "Nixos TUI Installer";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    gather-linux.url = "github:simonkoeck/gather-linux";
    gather-linux.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, fenix, disko, nixos-hardware, gather-linux, ... }@inputs:
  let
    system = "x86_64-linux";
    mkRustToolchain = fenix.packages.${system}.complete.withComponents;
    pkgs = import nixpkgs { inherit system; };
    diskoPkg = disko.packages.${system}.disko;
    nixosWizard = pkgs.rustPlatform.buildRustPackage {
      pname = "nixos-wizard";
      version = "0.3.2";

      src = self;

      cargoLock.lockFile = ./Cargo.lock;

      buildInputs = [ pkgs.makeWrapper ];

      postInstall = ''
        wrapProgram $out/bin/nixos-wizard \
        --prefix PATH : ${pkgs.lib.makeBinPath [
          diskoPkg
          pkgs.bat
          pkgs.nixfmt-rfc-style
          pkgs.nixfmt-classic
          pkgs.util-linux
          pkgs.gawk
          pkgs.gnugrep
          pkgs.gnused
          pkgs.ntfs3g
        ]}
      '';
    };
  in
  rec {
    nixosConfigurations = {
      installerIso = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs nixosWizard; };
        modules = [
          ./isoimage/config.nix
        ];
      };
      installerIsoGraphical = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs nixosWizard; };
        modules = [
          ./isoimage/config-graphical.nix
        ];
      };
    };

    isoImage = nixosConfigurations.installerIso.config.system.build.isoImage;
    isoImageGraphical = nixosConfigurations.installerIsoGraphical.config.system.build.isoImage;

    packages.${system} = {
      default = nixosWizard;
    };

    devShells.${system}.default = let
      toolchain = mkRustToolchain [
        "cargo"
        "clippy"
        "rustfmt"
        "rustc"
      ];
    in
      pkgs.mkShell {
        packages = [ toolchain pkgs.rust-analyzer ];

        shellHook = ''
          export SHELL=${pkgs.zsh}/bin/zsh
          exec ${pkgs.zsh}/bin/zsh
        '';
      };
  };
}
