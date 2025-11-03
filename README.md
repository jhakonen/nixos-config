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

# Tilan tekeminen nix storeen

```bash
nh clean all --keep 5 --keep-since 30d
```

Minulla on myös automaattinen puhdistus otettu käyttöön kaikilla NixOS koneilla joten tätä ei tarvitse välttämättä tehdä.

# Salaisuudet

Salaisuudet on jaettu kahteen eri kansioon:

- `agenix`: Agenix työkalulla kryptatut salaisuudet, nämä ovat kryptattuna nix-storessa ja salaus puretaan vasta aktivointivaiheessa.
- `encrypted`: Git-crypt työkalulla kryptatut salaisuudet, nämä on selkokielisenä nix-storessa. Salaus puretaan git pullin yhteydessä.

## Agenix

Tiedostot `agenix` kansiossa joiden pääte on `.age` ovat salattuja tiedostoja.

Uuden salatun tiedoston lisäys tapahtuu lisäämällä tiedostolle rivi `agenix/secrets.nix` tiedostoon. Sen jälkeen luo tiedosto komennolla:

```bash
cd agenix
agenix -e <salaisuus>.age
```

Salatun tiedoston muokkaus tapahtuu samalla komennolla.

Salatun tiedoston poistaminen tapahtuu poistamalla sen `.age`-tiedosto. Poista myös sen rivi `agenix/secrets.nix` tiedostosta.

Jos muutat tiedostojen julkisia avaimia `agenix/secrets.nix` tiedostossa, niin silloin tulee ajaa komento:

```bash
cd agenix
agenix --rekey
```

## Git-crypt

Kaikki tiedostot `encrypted` kansiossa (ja alikansioissa) salataan ja puretaan automaattisesti `git` komentojen yhteydessä.

Tiedostot voi halutessaan salata niin että tiedostot ovat salattuna levyllä käyttäen komentoa:

```bash
git crypt lock
```

Tiedostojen palautus kryptaamattomiksi tapahtuu komennolla:

```bash
git crypt unlock ./nixos-config.key
```

Avaintiedosto on salasanakannassa.


# Varmuuskopiot

## Varmuuskopioiden listaus

```bash
sudo restic-<palvelu> snapshots

# Esimerkiksi:
sudo restic-grafana snapshots
```

## Varmuuskopion palauttaminen
```bash
sudo restic-<palvelu> restore <snapshot> --target <kohde>

# Esimerkkiksi:
sudo restic-grafana restore latest --target /tmp/restored
```

## Palvelun varmuuskopiointi

```bash
systemctl start restic-backups-<palvelu>.service

# Esimerkkiksi:
systemctl start restic-backups-grafana.service
```
