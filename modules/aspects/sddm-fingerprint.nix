# Mahdollistaa sisäänkirjautumisen käyttäen sormenjäljenlukijaa ilman salasanan syöttämistä
#
# Perustuu repon ohjeisiin:
#   https://github.com/xCaptaiN09/sddm-fingerprint
# Patchi on tehty komennoilla:
#   git clone https://github.com/xCaptaiN09/sddm.git; cd sddm
#   git diff develop fingerprint-parallel-auth > ~/nixos-config/data/xCaptaiN09-fingerprint-auth.patch
{
  den.aspects.raami.nixos = { config, pkgs, lib, ... }: {

    # Pätsää SDDM
    services.displayManager.sddm.package = lib.mkForce (
      pkgs.kdePackages.sddm.override {
        sddm-unwrapped = pkgs.kdePackages.sddm-unwrapped.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            ../../data/xCaptaiN09-fingerprint-auth.patch
          ];
        });
      }
    );

    # Määritä minä käyttäjänä kirjaudutaan sisään kun käytetään
    # sormenjäljenlukijaa, osa pätsin vaatimaa muutosta
    environment.etc."sddm.conf.d/fingerprint.conf".text = ''
      [Fingerprintlogin]
      User=jhakonen
    '';

    # Määritä PAM konfiguraatio sormenjäljenlukijalle, osa pätsin vaatimaa
    # muutosta
    security.pam.services.sddm-fingerprint.text = ''
      auth        required  ${config.security.pam.package}/lib/security/pam_env.so
      auth        required  ${config.security.pam.package}/lib/security/pam_faillock.so preauth
      auth        required  ${config.security.pam.package}/lib/security/pam_shells.so
      auth        required  ${config.security.pam.package}/lib/security/pam_nologin.so
      auth        required  ${config.services.fprintd.package}/lib/security/pam_fprintd.so
      auth        optional  ${config.security.pam.package}/lib/security/pam_permit.so

      account     include   login
      password    substack  login
      session     include   login
    '';

    # Poista sormenjäljenlukija pois käytöstä jotta SDDM:ssä salasanan
    # syöttäminen ei jumita kunnes sormenjäljen lukeminen timeouttaa 
    security.pam.services.login.fprintAuth = false;
  };
}
