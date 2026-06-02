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
    mkNixosWizard = targetSystem: let
      pkgs = import nixpkgs { system = targetSystem; };
      diskoPkg = disko.packages.${targetSystem}.disko;
    in pkgs.rustPlatform.buildRustPackage {
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

    mkIso = { targetSystem, modules }: nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; nixosWizard = mkNixosWizard targetSystem; };
      modules = modules ++ [
        { nixpkgs.hostPlatform = targetSystem; }
      ];
    };

    devSystem = "x86_64-linux";
    mkRustToolchain = fenix.packages.${devSystem}.complete.withComponents;
    devPkgs = import nixpkgs { system = devSystem; };
  in
  rec {
    nixosConfigurations = {
      # x86_64
      installerIso = mkIso {
        targetSystem = "x86_64-linux";
        modules = [ ./isoimage/config.nix ];
      };
      installerIsoGraphical = mkIso {
        targetSystem = "x86_64-linux";
        modules = [ ./isoimage/config-graphical.nix ];
      };

      # aarch64
      installerIso-aarch64 = mkIso {
        targetSystem = "aarch64-linux";
        modules = [ ./isoimage/config.nix ];
      };
    };

    isoImage = nixosConfigurations.installerIso.config.system.build.isoImage;
    isoImageGraphical = nixosConfigurations.installerIsoGraphical.config.system.build.isoImage;
    isoImage-aarch64 = nixosConfigurations.installerIso-aarch64.config.system.build.isoImage;

    packages.${devSystem} = {
      default = mkNixosWizard devSystem;
    };

    devShells.${devSystem}.default = let
      toolchain = mkRustToolchain [
        "cargo"
        "clippy"
        "rustfmt"
        "rustc"
      ];
    in
      devPkgs.mkShell {
        packages = [ toolchain devPkgs.rust-analyzer ];

        shellHook = ''
          export SHELL=${devPkgs.zsh}/bin/zsh
          exec ${devPkgs.zsh}/bin/zsh
        '';
      };
  };
}
