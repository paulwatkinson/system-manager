{lib, ...}: {
  options.users = {
    groups = lib.mkOption {
      internal = true;
      default = {};
      type = lib.types.attrs;
    };

    users = lib.mkOption {
      internal = true;
      default = {};
      type = lib.types.attrs;
    };

    ldap = lib.mkOption {
      internal = true;
      default = {
        enable = false;
        loginPam = false;
      };
      type = lib.types.attrs;
    };

    mysql = lib.mkOption {
      internal = true;
      default.enable = false;
      type = lib.types.attrs;
    };
  };
}
