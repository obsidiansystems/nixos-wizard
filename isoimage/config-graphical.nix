{ pkgs, lib, modulesPath, ... }: {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-graphical-gnome.nix"
    ./config-common.nix
  ];

  # LTS kernel
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages;

  # Trim ISO size — exclude GNOME apps not needed for the installer
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    orca
    gnome-maps
    gnome-music
    gnome-weather
    gnome-contacts
    gnome-calendar
    gnome-clocks
    gnome-characters
    gnome-font-viewer
    gnome-connections
    gnome-logs
    epiphany
    totem
    yelp
    evince
    geary
    cheese
    simple-scan
    snapshot
    baobab
  ];

  # Better compression to fit under 2GB GitHub release limit
  isoImage.squashfsCompression = "xz -Xdict-size 100%";

  # Disable docs to save ~800MB (ghc-doc, gnome-user-docs, man pages)
  documentation.enable = lib.mkForce false;

  # Disable TTS/speech to save ~300MB (mbrola-voices, flite, speechd)
  services.speechd.enable = lib.mkForce false;

  # Trimmed firmware — only AMD GPU, AMD microcode, Intel WiFi/BT (Framework laptop)
  hardware.enableRedistributableFirmware = lib.mkForce false;
  hardware.firmware = lib.mkForce [
    (pkgs.runCommandLocal "linux-firmware-framework" {} ''
      mkdir -p $out/lib/firmware
      for dir in amdgpu amd intel; do
        cp -rL ${pkgs.linux-firmware}/lib/firmware/$dir $out/lib/firmware/
      done
      # iwlwifi ucode files are at the top level
      cp -L ${pkgs.linux-firmware}/lib/firmware/iwlwifi-* $out/lib/firmware/
    '')
    pkgs.sof-firmware
  ];

  # Disable Samba file sharing
  services.samba.enable = lib.mkForce false;

  environment.systemPackages = [ pkgs.gnome-terminal ];

  # Disable GNOME background services that cause heavy I/O on login
  services.gnome.tracker-miners.enable = false;
  services.gnome.tracker.enable = false;
  services.gnome.gnome-online-accounts.enable = false;
  services.gnome.evolution-data-server.enable = lib.mkForce false;
  services.gnome.gnome-software.enable = false;

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
