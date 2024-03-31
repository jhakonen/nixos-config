# Taskien listaus

```bash
deploy --list-all
```

# Konfiguraation deployaus

```bash
deploy <kone>
```

Esim.

```bash
deploy dellxps13
```

Debuggaus:

```bash
deploy <kone>-debug
```

# Järjestelmien päivitys

Flake lockin inputtien päivitys uusimpaan:
```bash
nix flake update
```

Kaikkien koneiden päivitys:
```bash
deploy -p all
```

Koneiden uudelleen käynnistys:
```
deploy kota-portti:reboot mervi:reboot nas-toolbox:reboot
sudo reboot
```

Jos etäkone ei löydä pakettia cache.nixos.org:sta ja sen käännös epäonnistuu, paketin voi kokeilla asentaa läppärillä ja lähettää sen etäkoneelle ennen deployn uudelleenyritystä.

Esimerkkinä grafanan käännös feilaa nas-toolbox koneella:
```
nix shell --inputs-from . nixpkgs#grafana
which grafana
> /nix/store/bgxpkjnfx9dp3yyjvkcrmcpmga0qiy1w-grafana-10.2.6/bin/grafana
nix-copy-closure --to root@nas-toolbox /nix/store/bgxpkjnfx9dp3yyjvkcrmcpmga0qiy1w-grafana-10.2.6
```
