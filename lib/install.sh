#!/usr/bin/env bash
#
# Install the specified packages

function cmd::install {
  local pkgs=()

  declare opt_all opt__list
  parseopts "a" "all" "$@" || exit 1
  cmd::install::validates_args "$@"

  # Read the packages from parameters or get all from the $pkg_base_path
  if $opt_all; then mapfile -t pkgs < <(list_pkgs); else pkgs=("${opt__list[@]}"); fi

  if install_pkgs "${pkgs[@]}"; then
    msg "${#pkgs[@]} package(s) installed."
  fi
}

function cmd::install::validates_args {
  validates_all_or_package_argument_list "cmd::install::help" "$opt_all" "${#opt__list[@]}"
}

function cmd::install::help {
  echo ""
  echo "Usage: $0 install [OPTIONS] [<PKG> ...]"
  echo ""
  echo "Install the specified PKGs."
  echo ""
  echo "Options:"
  echo "  -a, --all       Instead of passing each separate package as argument, you can use this"
  echo "                  to install all packages from this git repository."
}

function install_pkgs {
  msg "Installing packages..."
  sudo pacman -Sy --needed --noconfirm "$@"
}
