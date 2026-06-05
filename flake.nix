{
  description = "Nixos TUI Installer";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    fenix.url = "github:nix-community/fenix";
    disko.url = "github:nix-community/disko/latest";
  };

  outputs = { self, nixpkgs, fenix, disko }@inputs:
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
  in
  rec {
    nixosConfigurations = {
      "installerIso-x86_64" = mkIso {
        targetSystem = "x86_64-linux";
        modules = [ ./isoimage/config.nix ];
      };
      "installerIso-aarch64" = mkIso {
        targetSystem = "aarch64-linux";
        modules = [ ./isoimage/config.nix ];
      };
      "installerIsoGraphical-x86_64" = mkIso {
        targetSystem = "x86_64-linux";
        modules = [ ./isoimage/config-graphical.nix ];
      };
      "installerIsoGraphical-aarch64" = mkIso {
        targetSystem = "aarch64-linux";
        modules = [ ./isoimage/config-graphical.nix ];
      };
    };

    isoImage-x86_64 = nixosConfigurations."installerIso-x86_64".config.system.build.isoImage;
    isoImage-aarch64 = nixosConfigurations."installerIso-aarch64".config.system.build.isoImage;
    isoImageGraphical-x86_64 = nixosConfigurations."installerIsoGraphical-x86_64".config.system.build.isoImage;
    isoImageGraphical-aarch64 = nixosConfigurations."installerIsoGraphical-aarch64".config.system.build.isoImage;

    packages.x86_64-linux.default = mkNixosWizard "x86_64-linux";
    packages.aarch64-linux.default = mkNixosWizard "aarch64-linux";

    devShells = nixpkgs.lib.genAttrs (builtins.attrNames fenix.packages) (devSystem: let
      devPkgs = import nixpkgs { system = devSystem; };
      toolchain = fenix.packages.${devSystem}.complete.withComponents [
        "cargo" "clippy" "rustfmt" "rustc"
      ];
    in {
      default = devPkgs.mkShell {
        packages = [ toolchain devPkgs.rust-analyzer ];
      };
    });
  };
}
