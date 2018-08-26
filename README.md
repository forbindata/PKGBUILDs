# Arch PKGBUILDs

[![CircleCI](https://circleci.com/gh/kriansa/PKGBUILDs.svg?style=svg)](https://circleci.com/gh/kriansa/PKGBUILDs)

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

## Packages

All packages are currently available at `src` directory.

## CI/CD Infrastructure

I use CircleCI to build all my packages using a customized infrastructure. One
thing to have in mind if you wanna fork this project is to remember to add the
following environment variables to your CI:

* **REPO_NAME** - This is the Pacman repository name
* **AWS_PROFILE** or **AWS_ACCESS_KEY_ID** & **AWS_SECRET_ACCESS_KEY** - This
  is used to authenticate at AWS S3 to store the built packages.
* **AWS_S3_BUCKET_NAME** - This is used to determine to which AWS S3 bucket we
  need to upload the packages to.

## License

The contents of this repository are licensed under 3-Clause BSD. Each package
has its own license.
