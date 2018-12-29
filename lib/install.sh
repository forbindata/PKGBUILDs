#!/usr/bin/env bash
#
# Install the specified packages

function cmd::install {
  local pkgs=()

  # Read the packages from parameters or get all from the $pkg_base_path
  if [ $# -gt 0 ]; then pkgs=("$@"); else mapfile -t pkgs < <(list_pkgs); fi

  if install_pkgs "${pkgs[@]}"; then
    success "${#pkgs[@]} package(s) installed."
  fi
}

function install_pkgs {
  sudo pacman -Sy --needed --noconfirm "$@"
}
