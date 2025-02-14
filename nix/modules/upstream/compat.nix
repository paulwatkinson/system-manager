# Although unused here, we need to specify the values to enforce their
# existence for the upstream modules
{
  baseModules,
  config,
  extraModules,
  lib,
  modules,
  modulesPath,
  nixosModulesPath,
  options,
  pkgs,
  utils,
  ...
} @ args: let
  suppressedModules = [
    "/config/nix-channel.nix"
    "/config/nix-flakes.nix"
    "/config/nix-remote-build.nix"
    "/config/nix.nix"
    "/config/users-groups.nix"
    "/installer/tools/tools.nix"
    "/misc/documentation.nix"
    "/misc/extra-arguments.nix"
    "/misc/nixpkgs.nix"
    "/security/systemd-confinement.nix"
    "/services/misc/nix-gc.nix"
    "/services/misc/nix-optimise.nix"
    "/services/misc/nix-ssh-serve.nix"
    "/services/system/nix-daemon.nix"
    "/system/boot/loader/grub/grub.nix"
    "/system/boot/stage-1.nix"
    "/system/boot/stage-2.nix"
    "/system/boot/systemd.nix"
    "/system/boot/systemd/tmpfiles.nix"
    "/system/etc/etc-activation.nix"
    "/system/etc/etc.nix"
    "/testing/service-runner.nix"
    "/virtualisation/nixos-containers.nix"
  ];

  blockedModules = [
    "/installer/tools/tools.nix"
  ];

  upstreamModules =
    builtins.map
    (v: "/" + (builtins.concatStringsSep "/" (lib.drop 6 (lib.splitString "/" (toString v)))))
    (builtins.filter
      builtins.isPath
      (import (nixosModulesPath + "/module-list.nix")));

  enabledUpstreamModules = builtins.filter (v: !(builtins.elem v suppressedModules)) upstreamModules;

  blockedOptions = [
    "systemd"
  ];

  partialOptions = {
    systemd = lib.getAttrs [
      "tmpfiles"
      "defaultUnit"
      "enableCgroupAccounting"
      "suppressedSystemUnits"
    ];

    system = lib.flip builtins.removeAttrs ["etc"];
  };

  suppressedEnvironmentFiles = [
    "lsb-release"
    "os-release"
    "lvm/lvm.conf"
    "fstab"
    "sudoers"
  ];
in {
  imports =
    (map (path: nixosModulesPath + path) enabledUpstreamModules)
    ++ (builtins.foldl'
      (prev: path: let
        module = import (nixosModulesPath + path) args;
        imports = builtins.filter (v: !builtins.isPath v) (module.imports or []);
      in
        prev ++ imports)
      []
      (builtins.filter (v: !builtins.elem v blockedModules) suppressedModules));

  options = let
    raw =
      builtins.foldl'
      (prev: path: let
        module = import (nixosModulesPath + path) args;
      in
        lib.attrsets.recursiveUpdate prev (module.options or {}))
      {}
      suppressedModules;
  in
    (builtins.removeAttrs raw blockedOptions)
    // (builtins.mapAttrs (name: fn: fn raw.${name}) partialOptions);

  config = {
    networking.enableIPv6 = lib.mkDefault true;

    environment.etc =
      builtins.listToAttrs
      (builtins.map
        (name: {
          inherit name;
          value.enable = false;
        })
        suppressedEnvironmentFiles);

    system.activationScripts = {
      users = "";
      groups = "";
    };
  };
}
