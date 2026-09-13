{ buildGoModule }:
buildGoModule {
  name = "koti";
  src = ./.;
  vendorHash = null;
}
