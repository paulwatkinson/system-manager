{
  nixosModulesPath,
  lib,
  config,
  pkgs,
  utils,
  ...
} @ args: let
  cfg = config.systemd;
  systemd-lib = utils.systemdUtils.lib;
in {
  inherit (import (nixosModulesPath + "/system/boot/systemd.nix") args) options;

  config = {
    systemd = {
      targets.system-manager = {
        wantedBy = ["default.target"];
      };

      timers = lib.mapAttrs (name: service: {
        wantedBy = ["timers.target"];
        timerConfig.OnCalendar = service.startAt;
      }) (lib.filterAttrs (name: service: service.enable && service.startAt != []) cfg.services);

      units =
        lib.mapAttrs' (n: v: lib.nameValuePair "${n}.path" (systemd-lib.pathToUnit v)) cfg.paths
        // lib.mapAttrs' (n: v: lib.nameValuePair "${n}.service" (systemd-lib.serviceToUnit v)) cfg.services
        // lib.mapAttrs' (n: v: lib.nameValuePair "${n}.slice" (systemd-lib.sliceToUnit v)) cfg.slices
        // lib.mapAttrs' (n: v: lib.nameValuePair "${n}.socket" (systemd-lib.socketToUnit v)) cfg.sockets
        // lib.mapAttrs' (n: v: lib.nameValuePair "${n}.target" (systemd-lib.targetToUnit v)) cfg.targets
        // lib.mapAttrs' (n: v: lib.nameValuePair "${n}.timer" (systemd-lib.timerToUnit v)) cfg.timers
        // lib.listToAttrs (
          map (
            v: let
              n = utils.escapeSystemdPath v.where;
            in
              lib.nameValuePair "${n}.mount" (systemd-lib.mountToUnit v)
          )
          cfg.mounts
        )
        // lib.listToAttrs (
          map (
            v: let
              n = utils.escapeSystemdPath v.where;
            in
              lib.nameValuePair "${n}.automount" (systemd-lib.automountToUnit v)
          )
          cfg.automounts
        );
    };

    environment.etc = let
      allowCollisions = true;

      enabledUnits = lib.filterAttrs (_: unit: unit.enable) cfg.units;
      upstreamUnits =
        [
          # Targets
          "basic.target"
          "sysinit.target"
          "sockets.target"
          "exit.target"
          "graphical.target"
          "multi-user.target"
          "network.target"
          "network-pre.target"
          "network-online.target"
          "nss-lookup.target"
          "nss-user-lookup.target"
          "time-sync.target"
          "first-boot-complete.target"
        ]
        ++ lib.optionals cfg.package.withCryptsetup [
          "cryptsetup.target"
          "cryptsetup-pre.target"
          "remote-cryptsetup.target"
        ]
        ++ [
          "sigpwr.target"
          "timers.target"
          "paths.target"
          "rpcbind.target"

          # Rescue mode.
          "rescue.target"
          "rescue.service"

          # systemd-debug-generator
          "debug-shell.service"

          # Udev.
          "systemd-udevd-control.socket"
          "systemd-udevd-kernel.socket"
          "systemd-udevd.service"
          "systemd-udev-settle.service"
        ]
        ++ (lib.optional (!config.boot.isContainer) "systemd-udev-trigger.service")
        ++ [
          # hwdb.bin is managed by NixOS
          # "systemd-hwdb-update.service"

          # Consoles.
          "getty.target"
          "getty-pre.target"
          "getty@.service"
          "serial-getty@.service"
          "console-getty.service"
          "container-getty@.service"
          "systemd-vconsole-setup.service"

          # Hardware (started by udev when a relevant device is plugged in).
          "sound.target"
          "bluetooth.target"
          "printer.target"
          "smartcard.target"

          # Kernel module loading.
          "systemd-modules-load.service"
          "kmod-static-nodes.service"
          "modprobe@.service"

          # Filesystems.
          "systemd-fsck@.service"
          "systemd-fsck-root.service"
          "systemd-growfs@.service"
          "systemd-growfs-root.service"
          "systemd-remount-fs.service"
          "systemd-pstore.service"
          "local-fs.target"
          "local-fs-pre.target"
          "remote-fs.target"
          "remote-fs-pre.target"
          "swap.target"
          "dev-hugepages.mount"
          "dev-mqueue.mount"
          "sys-fs-fuse-connections.mount"
        ]
        ++ (lib.optional (!config.boot.isContainer) "sys-kernel-config.mount")
        ++ [
          "sys-kernel-debug.mount"

          # Hibernate / suspend.
          "hibernate.target"
          "suspend.target"
          "suspend-then-hibernate.target"
          "sleep.target"
          "hybrid-sleep.target"
          "systemd-hibernate.service"
          # "systemd-hibernate-clear.service"
          "systemd-hybrid-sleep.service"
          "systemd-suspend.service"
          "systemd-suspend-then-hibernate.service"

          # Reboot stuff.
          "reboot.target"
          "systemd-reboot.service"
          "poweroff.target"
          "systemd-poweroff.service"
          "halt.target"
          "systemd-halt.service"
          "shutdown.target"
          "umount.target"
          "final.target"
          "kexec.target"
          "systemd-kexec.service"
        ]
        ++ lib.optional cfg.package.withUtmp "systemd-update-utmp.service"
        ++ [
          # Password entry.
          "systemd-ask-password-console.path"
          "systemd-ask-password-console.service"
          "systemd-ask-password-wall.path"
          "systemd-ask-password-wall.service"

          # Varlink APIs
          "systemd-bootctl@.service"
          "systemd-bootctl.socket"
          "systemd-creds@.service"
          "systemd-creds.socket"
        ]
        ++ lib.optional cfg.package.withTpm2Tss [
          "systemd-pcrlock@.service"
          "systemd-pcrlock.socket"
        ]
        ++ [
          # Slices / containers.
          "slices.target"
        ]
        ++ lib.optionals cfg.package.withImportd [
          "systemd-importd.service"
        ]
        ++ lib.optionals cfg.package.withMachined [
          "machine.slice"
          "machines.target"
          "systemd-machined.service"
        ]
        ++ [
          "systemd-nspawn@.service"

          # Misc.
          "systemd-sysctl.service"
          "systemd-machine-id-commit.service"
        ]
        ++ lib.optionals cfg.package.withTimedated [
          "dbus-org.freedesktop.timedate1.service"
          "systemd-timedated.service"
        ]
        ++ lib.optionals cfg.package.withLocaled [
          "dbus-org.freedesktop.locale1.service"
          "systemd-localed.service"
        ]
        ++ lib.optionals cfg.package.withHostnamed [
          "dbus-org.freedesktop.hostname1.service"
          "systemd-hostnamed.service"
          "systemd-hostnamed.socket"
        ]
        ++ lib.optionals cfg.package.withPortabled [
          "dbus-org.freedesktop.portable1.service"
          "systemd-portabled.service"
        ]
        ++ [
          "systemd-exit.service"
          "systemd-update-done.service"
        ]
        ++ cfg.additionalUpstreamSystemUnits;

      upstreamWants = [
        "sysinit.target.wants"
        "sockets.target.wants"
        "local-fs.target.wants"
        "multi-user.target.wants"
        "timers.target.wants"
      ];

      lndir = "${pkgs.buildPackages.xorg.lndir}/bin/lndir";
    in {
      "systemd/system".source =
        pkgs.runCommand "system-manager-units"
        {
          preferLocalBuild = true;
          allowSubstitutes = false;
        }
        ''
          mkdir -p $out

          # Copy the upstream systemd units we're interested in.
          for i in ${toString upstreamUnits}; do
            fn=${cfg.package}/example/systemd/system/$i
            if ! [ -e $fn ]; then echo "missing $fn"; false; fi
            if [ -L $fn ]; then
              target="$(readlink "$fn")"
              if [ ''${target:0:3} = ../ ]; then
                ln -s "$(readlink -f "$fn")" $out/
              else
                cp -pd $fn $out/
              fi
            else
              ln -s $fn $out/
            fi
          done

          # Copy .wants links, but only those that point to units that
          # we're interested in.
          for i in ${toString upstreamWants}; do
            fn=${cfg.package}/example/systemd/system/$i
            if ! [ -e $fn ]; then echo "missing $fn"; false; fi
            x=$out/$(basename $fn)
            mkdir $x
            for i in $fn/*; do
              y=$x/$(basename $i)
              cp -pd $i $y
              if ! [ -e $y ]; then rm $y; fi
            done
          done

          # Symlink all units provided listed in systemd.packages.
          packages="${toString cfg.packages}"

          # Filter duplicate directories
          declare -A unique_packages
          for k in $packages ; do unique_packages[$k]=1 ; done

          for i in ''${!unique_packages[@]}; do
            for fn in $i/etc/systemd/system/* $i/lib/systemd/system/*; do
              if ! [[ "$fn" =~ .wants$ ]]; then
                if [[ -d "$fn" ]]; then
                  targetDir="$out/$(basename "$fn")"
                  mkdir -p "$targetDir"
                  ${lndir} "$fn" "$targetDir"
                else
                  ln -s $fn $out/
                fi
              fi
            done
          done

          # Symlink units defined by systemd.units where override strategy
          # shall be automatically detected. If these are also provided by
          # systemd or systemd.packages, then add them as
          # <unit-name>.d/overrides.conf, which makes them extend the
          # upstream unit.
          for i in ${toString (lib.mapAttrsToList
            (n: v: v.unit)
            (lib.filterAttrs (n: v: (lib.attrByPath ["overrideStrategy"] "asDropinIfExists" v) == "asDropinIfExists") cfg.units))}; do
            fn=$(basename $i/*)
            if [ -e $out/$fn ]; then
              if [ "$(readlink -f $i/$fn)" = /dev/null ]; then
                ln -sfn /dev/null $out/$fn
              else
                ${
            if allowCollisions
            then ''
              mkdir -p $out/$fn.d
              ln -s $i/$fn $out/$fn.d/overrides.conf
            ''
            else ''
              echo "Found multiple derivations configuring $fn!"
              exit 1
            ''
          }
              fi
           else
              ln -fs $i/$fn $out/
            fi
          done

          # Symlink units defined by systemd.units which shall be
          # treated as drop-in file.
          for i in ${toString (lib.mapAttrsToList
            (n: v: v.unit)
            (lib.filterAttrs (n: v: v ? overrideStrategy && v.overrideStrategy == "asDropin") cfg.units))}; do
            fn=$(basename $i/*)
            mkdir -p $out/$fn.d
            ln -s $i/$fn $out/$fn.d/overrides.conf
          done

          ${lib.concatStrings (
            lib.mapAttrsToList (
              name: unit:
                lib.concatMapStrings (name2: ''
                  mkdir -p $out/'${name2}.wants'
                  ln -sfn '../${name}' $out/'${name2}.wants'/
                '') (unit.wantedBy or [])
            )
            enabledUnits
          )}

          ${lib.concatStrings (
            lib.mapAttrsToList (
              name: unit:
                lib.concatMapStrings (name2: ''
                  mkdir -p $out/'${name2}.requires'
                  ln -sfn '../${name}' $out/'${name2}.requires'/
                '') (unit.requiredBy or [])
            )
            enabledUnits
          )}
        '';
    };
  };
}
