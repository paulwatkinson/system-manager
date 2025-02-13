{lib, ...}: {
  options.security = {
    sudo = lib.mkOption {
      internal = true;
      default.enable = false;
      type = lib.types.attrs;
    };

    sudo-rs = lib.mkOption {
      internal = true;
      default.enable = false;
      type = lib.types.attrs;
    };

    apparmor = lib.mkOption {
      internal = true;
      default.enable = false;
      type = lib.types.attrs;
    };

    pam.oath = lib.mkOption {
      internal = true;
      default.enable = false;
      type = lib.types.attrs;
    };
  };
}
