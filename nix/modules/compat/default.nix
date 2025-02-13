{
  lib,
  nixosModulesPath,
  pkgs,
  ...
}: {
  imports =
    [
      ./security.nix
      ./services.nix
      ./users.nix
    ]
    ++ (map (path: nixosModulesPath + path) [
      "/system/build.nix"
      "/system/activation/top-level.nix"
      "/system/activation/activation-script.nix"
      "/system/boot/systemd/user.nix"

      "/security/wrappers"
      "/security/pam.nix"
      "/security/pam_mount.nix"

      "/config/shells-environment.nix"
      "/config/system-environment.nix"
    ]);

  options = {
    nix = lib.mkOption {
      internal = true;
      default.enable = false;
      type = lib.types.attrs;
    };
  };

  config = {
    environment.profileRelativeSessionVariables = {};
    security.pam.krb5.enable = false;

    system.build.earlyMountScript = pkgs.writeText "mounts.sh" ''
      # NO-OP
    '';
  };
}
