{ pkgs, lib, modulesPath, nixosWizard, ... }: {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-graphical-gnome.nix"
    ./config-common.nix
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
  hardware.wirelessRegulatoryDatabase = true;
  # x86_64: trim firmware for the Framework 13 lineup
  # AMD: amdgpu, amd (microcode), MediaTek WiFi+BT
  # Intel Core Ultra 1 (Meteor Lake): i915 (Arc Graphics), intel (VPU, BT), iwlwifi (AX210)
  # (aarch64 falls back to the default redistributable set)
  hardware.enableRedistributableFirmware = lib.mkIf pkgs.stdenv.hostPlatform.isx86_64 (lib.mkForce false);
  hardware.firmware = lib.mkIf pkgs.stdenv.hostPlatform.isx86_64 (lib.mkForce [
    (pkgs.runCommandLocal "linux-firmware-framework" {} ''
      mkdir -p $out/lib/firmware
      for dir in amdgpu amd intel i915; do
        cp -rL ${pkgs.linux-firmware}/lib/firmware/$dir $out/lib/firmware/
      done
      # iwlwifi ucode files are at the top level
      cp -L ${pkgs.linux-firmware}/lib/firmware/iwlwifi-* $out/lib/firmware/
      # MediaTek WiFi+BT — Framework 13 AMD (RZ616/MT7922, RZ717/MT7925)
      mkdir -p $out/lib/firmware/mediatek
      cp -L ${pkgs.linux-firmware}/lib/firmware/mediatek/*MT7922* $out/lib/firmware/mediatek/
      cp -rL ${pkgs.linux-firmware}/lib/firmware/mediatek/mt792? $out/lib/firmware/mediatek/
    '')
    pkgs.sof-firmware
  ]);

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
