{ pkgs, lib, modulesPath, ... }: {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-graphical-gnome.nix"
    ./config-common.nix
  ];

  # LTS kernel
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages;

  # Skip GNOME Tour on first login
  environment.gnome.excludePackages = [ pkgs.gnome-tour ];

  environment.systemPackages = [ pkgs.gnome-terminal ];

  # Force dark theme for GNOME Terminal
  programs.dconf.profiles.user.databases = [{
    settings."org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
      use-theme-colors = true;
    };
    settings."org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
    settings."org/gnome/shell" = {
      welcome-dialog-last-shown-version = "999.0";
    };
  }];

  # Auto-launch nixos-wizard in a terminal on GNOME login
  environment.etc."xdg/autostart/nixos-wizard.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=NixOS Wizard
    Comment=NixOS Installer
    Exec=gnome-terminal --maximize -- sudo nixos-wizard
    Terminal=false
    X-GNOME-Autostart-enabled=true
  '';
}
