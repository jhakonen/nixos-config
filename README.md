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
