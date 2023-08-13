{ config, catalog, ... }:
let
  user = "koti";
in {
  # Salaisuudet
  age.secrets = {
    mosquitto-password = {
      file = ../../secrets/mqtt-password.age;
      owner = "mosquitto";
      group = "mosquitto";
    };
    mosquitto-key-file = {
      file = ../../secrets/wildcard-jhakonen-com.key.age;
      owner = "mosquitto";
      group = "mosquitto";
    };
  };

  # Julkinen sertifikaatti *.jhakonen.com domainille
  environment.etc."wildcard-jhakonen-com.cert".text = ''
    -----BEGIN CERTIFICATE-----
    MIIDyzCCArOgAwIBAgIUBJnGD7RBthXhjJ93Jsxc6nNvaSwwDQYJKoZIhvcNAQEL
    BQAwbjELMAkGA1UEBhMCRkkxEDAOBgNVBAcMB1RhbXBlcmUxEDAOBgNVBAoMB0tv
    dGkgT3kxFjAUBgNVBAMMDUphbm5lIEhha29uZW4xIzAhBgkqhkiG9w0BCQEWFGph
    bm5lLmhha29uZW5AaWtpLmZpMB4XDTIyMTIzMDIwMDQyN1oXDTMyMTIyNzIwMDQy
    N1owSjELMAkGA1UEBhMCRkkxEDAOBgNVBAcMB1RhbXBlcmUxEDAOBgNVBAoMB0tv
    dGkgT3kxFzAVBgNVBAMMDiouamhha29uZW4uY29tMIIBIjANBgkqhkiG9w0BAQEF
    AAOCAQ8AMIIBCgKCAQEAk6UB10hQFJP92y+y/EH8T/eG+sEBhyqX8CJzZD3E+2XZ
    kFIHa9AwiA3o9+6Q4sO6aD7qBSV4DmuYoesGqhOf6KakRT2RMea1bZU9GfBfyoG/
    g69MotEid+fLx9Z8o/AjbctAaLDW7O/86kCbJQzLM1Q/NFcMwZh8cirzIT2Lg++x
    9w9NWB3Nha8Xv67+baBD6Jn1ASSEbLAE1oh3GdLbkOSzWBp6if9RzNtgxAxs2+Nq
    YzJo/eGYNuLNhsmjS6dJmvGTLYsie7RTLp1z4pi1umjy6BMNz4k46fe0bclEyPAL
    iwZVtdL2Nc+Dc1KjCiBBUsse0CUzwkKjGrWqUx0Y0wIDAQABo4GEMIGBMB8GA1Ud
    IwQYMBaAFLWuzAgIaGkpO/zkK+YaV3dqHIXpMAkGA1UdEwQCMAAwCwYDVR0PBAQD
    AgTwMCcGA1UdEQQgMB6CDGpoYWtvbmVuLmNvbYIOKi5qaGFrb25lbi5jb20wHQYD
    VR0OBBYEFAi7ZTfX+EGe/78GSSVXtcrA+OR5MA0GCSqGSIb3DQEBCwUAA4IBAQBm
    lf8fCHdCZ+xH/F1eBzBi7ddetGEPJiA8evuSiTVm+0SsR0s0Ivg59NxNrqpSBElz
    YFpg9fewl+5yeCwT7+yN27nmI1pIQh43R5B7GPTzLMqtgymfqFdszUvN80/lWZqA
    tuhaeNROGwpsEek+q1d0Qz61yfH7BWtyM65rT0JOEsLw6DjhDdRU1eDEQHCZd2Vi
    XE+RVRsp2Q8qIzIF99dDMfsAN6NiP1n9UZRvbOjhCacSDw5N739VaggndURnJ8O9
    CRyGcdZbYaPUx24JVxPI+ldY8sq7B0cHWObdTIlM2FXlkudAa0kEIIslKS7twG7D
    0L00UiilmmH5nKd45+5R
    -----END CERTIFICATE-----
  '';

  services.mosquitto = {
    enable = true;
    listeners = [
      {
        port = catalog.services.mosquitto.port;
        settings = {
          certfile = "/etc/wildcard-jhakonen-com.cert";
          keyfile = config.age.secrets.mosquitto-key-file.path;
        };
        users."${user}" = {
          acl = [ "#" ];
          passwordFile = config.age.secrets.mosquitto-password.path;
        };
      }
    ];
  };
  networking.firewall.allowedTCPPorts = [ catalog.services.mosquitto.port ];
}
