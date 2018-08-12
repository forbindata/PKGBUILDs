# Arch PKGBUILDs

This repository is composed of PKGBUILDs I have written or modified from
existing packages in the Arch Build Service and Arch User Repository to help me
install packages not in the AUR or pacman repos, or have customized ones to
make them better suit my purposes.

## Repository

These packages are built automatically and uploaded to a repository. If you
want to use this repository, please add it to your `/etc/pacman.conf`:

```conf
[aur-kriansa]
Server = https://aur.garajau.com.br/
```

Then add my key to Pacman keyring:

```sh
# pacman-key --recv-keys 0x3E7884756312F945
# pacman-key --lsign-key 0x3E7884756312F945
```

All packages are available for `x86_64` only.

## License

The contents of this repository are licensed under 3-Clause BSD. Each package
has its own license.

## Packages

#### ttf-emojione

Official colorful EmojiOne font. No fontconfig present.

#### ttf-gelasio

Gelasio is designed to be metrics-compatible with Georgia.

#### ttf-nerd-glyphs

Patched font with all glyphs present on NerdFonts. No fontconfig present.
