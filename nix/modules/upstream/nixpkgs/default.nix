{
  pkgs,
  nixosModulesPath,
  lib,
  ...
}: let
  kernelVersion =
    builtins.readFile
    (pkgs.runCommand "kernel-version"
      {
        preferLocalBuild = true;
        allowSubstitutes = false;
      }
      ''
        printf '%s' "$(uname -r)" >$out
      '');
in {
  imports =
    [
      ./nginx.nix
    ]
    ++
    # List of imported NixOS modules
    # TODO: how will we manage this in the long term?
    map (path: nixosModulesPath + path) [
      "/misc/meta.nix"
      "/security/acme/"
      "/services/web-servers/nginx/"
    ];

  options =
    # We need to ignore a bunch of options that are used in NixOS modules but
    # that don't apply to system-manager configs.
    # TODO: can we print an informational message for things like kernel modules
    # to inform users that they need to be enabled in the host system?
    {
      boot = {
        isContainer = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };

        kernel = lib.mkOption {
          type = lib.types.raw;
          default.version = kernelVersion;
        };

        supportedFilesystems = lib.mkOption {
          type = lib.types.listOf lib.types.raw;
          default = [];
        };

        kernelModules = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
        };

        kernelPackages = lib.mkOption {
          type = lib.types.raw;
          default = {
            kernel.version = kernelVersion;
          };
        };

        systemd = {};
      };
    };
}
