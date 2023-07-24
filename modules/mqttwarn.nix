{ lib, pkgs, config, ... }:
let
  cfg = config.apps.mqttwarn;
  mqttwarn = pkgs.python3.pkgs.buildPythonApplication rec {
    pname = "mqttwarn";
    version = "0.34.1";

    # src = /home/jhakonen/mqttwarn;

    src = pkgs.fetchFromGitHub {
      owner = "jhakonen";
      repo = "mqttwarn";
      rev = "0b4d2952878e4f05a868a7138551d35d9b1ca1a0";
      hash = "sha256-Sjq23Immv6+oI7HQC8wi8H3Mm406ILWpxRwGKE3RNc4=";
    };

    # src = pkgs.fetchPypi {
    #   inherit pname version;
    #   hash = "sha256-3YoIuHi/U/AASlnoYPQF3t5idZTeCPhVjMZGzsJINrM=";
    # };
    # Tarvitaan kun ei käytetä fetchPypi() funktiota
    # nativeBuildInputs = [ pkgs.git ];

    propagatedBuildInputs = with pkgs.python3.pkgs; [
      attrs
      docopt
      funcy
      future
      jinja2
      paho-mqtt
      requests
      six
      versioningit
    ];

    # Pois päältä koska nixpkgs:ssä ei ole kaikkia tarvittavia riippuvuuksia
    doCheck = false;

    meta = {
      homepage = "https://mqttwarn.readthedocs.io/";
      description = "Subscribe to MQTT topics and notify pluggable services";
      license = lib.licenses.epl20;
      maintainers = [ ];
    };
  };
  settingsFormat = pkgs.formats.ini { };
  toPython = with builtins; input:
    if (isAttrs input) then
      "{" + (concatStringsSep "," (lib.attrsets.mapAttrsToList (name: value: "'${name}'=${toPython value}") input)) + "}"
    else if (isList input) then
      "[" + (concatStringsSep "," (map (item: toPython item) input)) + "]"
    else if (isBool input) then
      if input then "True" else "False"
    else if (isFloat input || isInt input) then
      toString input
    else if isNull input then
      "None"
    else if isString input then
      "'${input}'"
    else
      abort "Unsupported input: ${input}"
    ;

  pythonizeTargets = with builtins; settings:
    let
      pythonizeTargets = option: value: if option == "targets" then (toPython value) else value;
    in
    mapAttrs (section: options: (options: mapAttrs pythonizeTargets options) options) settings;

  configFile = settingsFormat.generate "mqttwarn.ini" (pythonizeTargets cfg.settings);
in {
  options.apps.mqttwarn = {
    enable = lib.mkEnableOption "Mqttwarn app";
    environmentFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [];
      example = [ "/run/keys/mqttwarn.env" ];
    };
    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = lib.types.attrs;
      };
      default = {};
      description = ''
        Configuration for Mqttwarn, see
        <link xlink:href="https://mqttwarn.readthedocs.io/en/latest/configure/"/>
        for supported values.
      '';
    };

  };

  config = lib.mkIf cfg.enable {
    systemd.services.mqttwarn = {
      description = "Mqttwarn pluggable mqtt notification service";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        EnvironmentFile = cfg.environmentFiles;
        Environment = [ "MQTTWARNINI=${configFile}" ];
        ExecStart = "${mqttwarn}/bin/mqttwarn";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
    environment.systemPackages = [ mqttwarn ];
    environment.etc."mqttwarn.ini".source = configFile;
  };
}
