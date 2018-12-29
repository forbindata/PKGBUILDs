#!/usr/bin/env bash
#
# Remove packages from $pkg_base_path

function cmd::remove {
  local pkgs=() removed_packages=0

  # Read the packages from parameters or get all from the $pkg_base_path
  if [ $# -gt 0 ]; then pkgs=("$@"); else mapfile -t pkgs < <(list_pkgs); fi

  for pkg in "${pkgs[@]}"; do
    remove_pkg_repo "$pkg" && ((removed_packages+=1))
  done

  if [ $removed_packages -le 0 ]; then
    success "No packages removed."
  else
    success "$removed_packages package(s) removed."
  fi
}

# Remove a single package from this git repo
function remove_pkg_repo {
  local pkg=$1

  local pkg_path="$pkg_base_path/$pkg"

  if ! [ -d "$pkg_path" ]; then
    error "Package $pkg not found."
    return 2
  fi

  # Remove the git submodule completely
  git rm "$pkg_path"
  rm -rf ".git/modules/$pkg_path"
  git config -f ".git/config" --remove-section "submodule.$pkg_path" 2> /dev/null

  # Then commit that change
  git commit -m ":fire: packages: remove $pkg"

  success "Package $pkg removed."
}
