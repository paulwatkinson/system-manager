{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    concatStrings
    concatStringsSep
    mapAttrsToList
    ;

  # generates a single entry for a tmpfiles.d rule
  settingsEntryToRule = path: entry: ''
    '${entry.type}' '${path}' '${entry.mode}' '${entry.user}' '${entry.group}' '${entry.age}' ${entry.argument}
  '';

  # generates a list of tmpfiles.d rules from the attrs (paths) under tmpfiles.settings.<name>
  pathsToRules = mapAttrsToList (
    path: types: concatStrings (mapAttrsToList (_type: settingsEntryToRule path) types)
  );

  mkRuleFileContent = paths: concatStrings (pathsToRules paths);
in {
  config = {
    environment.etc = {
      "tmpfiles.d".source = pkgs.symlinkJoin {
        name = "tmpfiles.d";
        paths = map (p: p + "/lib/tmpfiles.d") config.systemd.tmpfiles.packages;
        postBuild = ''
          for i in $(cat $pathsPath); do
            (test -d "$i" && test $(ls "$i"/*.conf | wc -l) -ge 1) || (
              echo "ERROR: The path '$i' from systemd.tmpfiles.packages contains no *.conf files."
              exit 1
            )
          done
        '';
      };
    };
    systemd.tmpfiles.packages =
      [
        (pkgs.writeTextFile {
          name = "system-manager-tmpfiles.d";
          destination = "/lib/tmpfiles.d/00-system-manager.conf";
          text = ''
            # This file is created automatically and should not be modified.
            # Please change the option ‘systemd.tmpfiles.rules’ instead.

            ${concatStringsSep "\n" config.systemd.tmpfiles.rules}
          '';
        })
      ]
      ++ (mapAttrsToList (
          name: paths: pkgs.writeTextDir "lib/tmpfiles.d/${name}.conf" (mkRuleFileContent paths)
        )
        config.systemd.tmpfiles.settings);
  };
}
