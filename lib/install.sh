#!/usr/bin/env bash
#
# Install the specified packages

function cmd::install {
  local pkgs=()

  # Read the packages from parameters or get all from the $pkg_base_path
  test $# -gt 0 && pkgs=("$@") || pkgs=("$(list_pkgs)")

  if install_pkgs "${pkgs[@]}"; then
    success "$# package(s) installed."
  fi
}

function install_pkgs {
  sudo pacman -Sy --needed --noconfirm "$@"
}
