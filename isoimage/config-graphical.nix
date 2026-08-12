{ pkgs, lib, modulesPath, ... }: {
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
  hardware.enableRedistributableFirmware = lib.mkForce false;
  hardware.firmware = lib.mkForce [
    (pkgs.runCommandLocal "linux-firmware-trimmed" {} (''
      mkdir -p $out/lib/firmware
    '' + lib.optionalString pkgs.stdenv.hostPlatform.isx86_64 ''
      # Framework 13 AMD: GPU, microcode, MediaTek WiFi+BT
      for dir in amdgpu amd; do
        cp -rL ${pkgs.linux-firmware}/lib/firmware/$dir $out/lib/firmware/
      done
      mkdir -p $out/lib/firmware/mediatek
      cp -L ${pkgs.linux-firmware}/lib/firmware/mediatek/*MT7922* $out/lib/firmware/mediatek/
      cp -rL ${pkgs.linux-firmware}/lib/firmware/mediatek/mt792? $out/lib/firmware/mediatek/
      # Framework 13 Intel Core Ultra 1 (Meteor Lake): Arc Graphics, VPU, BT, AX210 WiFi
      cp -rL ${pkgs.linux-firmware}/lib/firmware/i915 $out/lib/firmware/
      cp -rL ${pkgs.linux-firmware}/lib/firmware/intel $out/lib/firmware/
      cp -L ${pkgs.linux-firmware}/lib/firmware/iwlwifi-* $out/lib/firmware/
    '' + lib.optionalString pkgs.stdenv.hostPlatform.isAarch64 ''
      # Raspberry Pi 4B: Broadcom WiFi+BT
      mkdir -p $out/lib/firmware/brcm
      cp -L ${pkgs.linux-firmware}/lib/firmware/brcm/brcmfmac43455* $out/lib/firmware/brcm/
    ''))
    pkgs.sof-firmware
  ];

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
