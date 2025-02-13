{lib, ...}: {
  options.services = {
    kanidm = lib.mkOption {
      internal = true;
      default.enablePam = false;
      type = lib.types.attrs;
    };

    sssd = lib.mkOption {
      internal = true;
      default.enable = false;
      type = lib.types.attrs;
    };

    homed = lib.mkOption {
      internal = true;
      default.enable = false;
      type = lib.types.attrs;
    };

    intune = lib.mkOption {
      internal = true;
      default.enable = false;
      type = lib.types.attrs;
    };

    fprintd = lib.mkOption {
      internal = true;
      default.enable = false;
      type = lib.types.attrs;
    };
  };
}
