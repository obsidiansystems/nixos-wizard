{ pkgs, lib, modulesPath, nixosWizard, ... }: {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-graphical-gnome.nix"
    ./config.nix
  ];

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages;

  environment.gnome.excludePackages = with pkgs; [
    gnome-tour orca gnome-maps gnome-music gnome-weather
    gnome-contacts gnome-calendar gnome-clocks gnome-characters
    gnome-font-viewer gnome-connections gnome-logs
    epiphany totem yelp evince geary cheese
    simple-scan snapshot baobab
  ];

  isoImage.squashfsCompression = "xz -Xdict-size 100%";
  documentation.enable = lib.mkForce false;
  services.speechd.enable = lib.mkForce false;
  services.samba.enable = lib.mkForce false;

  environment.systemPackages = [ pkgs.gnome-terminal ];

  services.gnome.localsearch.enable = false;
  services.gnome.tinysparql.enable = false;
  services.gnome.gnome-online-accounts.enable = false;
  services.gnome.evolution-data-server.enable = lib.mkForce false;

  programs.dconf.profiles.user.databases = [{
    settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
    settings."org/gnome/shell".welcome-dialog-last-shown-version = "999.0";
  }];

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
