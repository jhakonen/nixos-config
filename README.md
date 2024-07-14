# Valmistelevat toimenpiteet uudella koneella

Kopioi Github identity tiedosto kohde koneelle:
```bash
scp ~/.ssh/github-id-rsa <kone>:
ssh <kone>
sudo su
mv github-id-rsa ~/.ssh/
chown root:root ~/.ssh/github-id-rsa
```

Lisää rootin `~/.ssh/config` tiedostoon:
```
Host github.com
  User git
  IdentityFile /root/.ssh/github-id-rsa
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
```


# Konfiguraation deployaus

```bash
koti rakenna <kone>
```

Esim.

```bash
koti rakenna dellxps13
```

Debuggaus:

```bash
koti rakenna --debug <kone>
```

# Järjestelmien päivitys

Flake lockin inputtien päivitys uusimpaan:
```bash
nix flake update
```

Kaikkien koneiden päivitys:
```bash
koti rakenna -t boot
```

Koneiden uudelleen käynnistys:
```
koti buuttaa
sudo reboot
```

Jos etäkone ei löydä pakettia cache.nixos.org:sta ja sen käännös epäonnistuu, paketin voi kokeilla asentaa läppärillä ja lähettää sen etäkoneelle ennen deployn uudelleenyritystä.

Esimerkkinä grafanan käännös feilaa kanto koneella:
```
nix shell --inputs-from . nixpkgs#grafana
which grafana
> /nix/store/bgxpkjnfx9dp3yyjvkcrmcpmga0qiy1w-grafana-10.2.6/bin/grafana
nix-copy-closure --to root@kanto /nix/store/bgxpkjnfx9dp3yyjvkcrmcpmga0qiy1w-grafana-10.2.6
```

# Järjestelmän päivitys uudempaan Nixos julkaisuun

Päivitä nix-kanava ja indeksi:
```bash
sudo nix-channel --add https://nixos.org/channels/nixos-24.05 nixos
sudo nix-channel --update
nix-index
```

Muokkaa `flake.nix` tiedostossa `inputs` osiossa vanhan version esim. `23.11` merkkijono arvoon `24.05`.

Päivitä lukkotiedosto:

```bash
nix flake update
```

Estä läppärin meneminen valmiustilaan jotta verkkoyhteys ei katkea kesken kaiken.

Testaa että päivitys onnistuu:

```bash
koti rakenna -t test <kone>
```

Lopuksi tee boot entry ja käynnistä kone uudelleen:

```bash
koti rakenna -t boot <kone>
koti buuttaa <kone>
```

Toista kullekkin koneelle.

# Sukupolvien listaus

```bash
nixos-rebuild list-generations
```

# Vanhojen sukupolvien poistaminen

Poista vanhat sukupolvet profiilista (säästäen 20 viimeisintä):
```bash
sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +20
```

Päivitä bootin lista sukupolvista:
```bash
sudo /run/current-system/bin/switch-to-configuration boot
```

# Tilan tekeminen nix storeen:

```bash
sudo nix-collect-garbage --delete-older-than 30d
```
Huomaa, että kannattaa ensin poistaa vanhoja sukupolvia, jotta garbage collector pystyy poistaan myös niiden viittaamat tiedostot storesta.

Minulla on myös automaattinen puhdistus otettu käyttöön kaikilla NixOS koneilla joten tätä ei tarvitse välttämättä tehdä.


# Muutosten testaaminen paikallisella private-flakella

Muuta julkisessa `flake.nix` tiedostossa `private` input muotoon:
```nix
private.url = "path:///home/jhakonen/nixos-config/private";
```

Deploymentti läppärillä:
```bash
nix flake lock --update-input private && koti rakenna dellxps13
```

Deploymentti etäkoneella:
```bash
# Aja ensin läppärillä
rsync -r ~/nixos-config <kone>:

# Aja etäkoneella
cd ~/nixos-config/public
nix flake lock --update-input private && sudo nixos-rebuild switch --flake '.#'
```
