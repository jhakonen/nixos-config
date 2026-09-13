{ buildGoModule }:
buildGoModule {
  name = "koti-go";
  src = ./.;
  vendorHash = null;
}
