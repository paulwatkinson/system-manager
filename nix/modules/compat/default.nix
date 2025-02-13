{
  nixosModulesPath,
  lib,
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

    systemd.additionalUpstreamSystemUnits = lib.mkOption {
      default = [];
      type = lib.types.listOf lib.types.str;
    };
  };

  config.environment.profileRelativeSessionVariables = {};
}
