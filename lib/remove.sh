#!/usr/bin/env bash
#
# Remove packages from $pkg_base_path

function cmd::remove {
  local pkgs=() removed_packages=0

  declare opt_all opt__list
  parseopts "a" "all" "$@" || exit 1
  cmd::remove::validates_args "$@"

  # Read the packages from parameters or get all from the $pkg_base_path
  if $opt_all; then mapfile -t pkgs < <(list_pkgs); else pkgs=("${opt__list[@]}"); fi

  for pkg in "${pkgs[@]}"; do
    remove_pkg_repo "$pkg" && ((removed_packages+=1))
  done

  # Then uninstall the packages
  uninstall_pkgs "${pkgs[@]}"

  if [ $removed_packages -le 0 ]; then
    msg "No packages removed."
  else
    msg "$removed_packages package(s) removed."
  fi
}

function cmd::remove::validates_args {
  validates_all_or_package_argument_list "cmd::remove::help" "$opt_all" "${#opt__list[@]}"
}

function cmd::remove::help {
  echo ""
  echo "Usage: $0 remove [OPTIONS] [<PKG> ...]"
  echo ""
  echo "Remove the specified PKGs."
  echo ""
  echo "Options:"
  echo "  -a, --all       Instead of passing each separate package as argument, you can use this"
  echo "                  to remove all packages from this git repository."
}

# Uninstall the packages from system
function uninstall_pkgs {
  sudo pacman -Rsc --noconfirm "$@"
}

# Remove a single package from this git repo
function remove_pkg_repo {
  local pkg=$1

  local pkg_path="${pkg_base_path:?}/$pkg"

  if ! [ -d "$pkg_path" ]; then
    error "Package $pkg not found."
    return 2
  fi

  # Set the output folder of the built package
  export PKGDEST; PKGDEST="$(dirname "${repo_db:?}")"

  # Remove the package from the repo
  repo-remove "$repo_db" "$pkg"

  # Remove the built package
  while IFS= read -r built_pkg_name; do
    rm "$built_pkg_name"
  done < <(cd "$pkg_path" && makepkg --packagelist)

  # Remove the git submodule completely
  git rm "$pkg_path"
  rm -rf ".git/modules/$pkg_path"
  git config -f ".git/config" --remove-section "submodule.$pkg_path" 2> /dev/null

  # Then commit that change
  git commit -m ":fire: packages: remove $pkg"

  msg "Package $pkg removed."
}
