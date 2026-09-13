# Koti

Tämä ohjelma tarjoaa työkalut jotka helpottavat NixOS koneiden hallintaa.

# Kääntäminen ja testaus

Käännä:

```bash
devenv shell
go build
./koti <argumentit>
```

Käännä ja aja lähdekoodeista:

```bash
devenv shell
go run main.go <argumentit>
```

# Ajaminen

```bash
./koti muokkaa
```

```bash
./koti rakenna -t test dellxps13
```

```bash
./koti buuttaa kanto
```

# Paketointi

```bash
nix-build
./result/bin/koti <argumentit>
```

# Sisällyttäminen nix konffaan

```nix
{
  environment.systemPackages = [
    (pkgs.callPackage ./packages/koti/koti.nix { })
  ];
}
```
