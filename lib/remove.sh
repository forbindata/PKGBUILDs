#!/usr/bin/env bash
#
# Remove packages from $pkg_base_path

function cmd::remove {
  local pkgs=() removed_packages=0 installed_packages=()

  declare opt_all opt_nocommit opt__list
  parseopts "an" "all,nocommit" "$@" || exit 1
  cmd::remove::validates_args "$@"

  # Read the packages from parameters or get all from the $pkg_base_path
  if $opt_all; then mapfile -t pkgs < <(list_pkgs); else pkgs=("${opt__list[@]}"); fi

  for pkg in "${pkgs[@]}"; do
    remove_pkg_repo "$pkg" "$opt_nocommit" && ((removed_packages+=1))

    # Check whether that package has been installed, so we flag it to removal
    pacman -Q "$pkg" > /dev/null 2>&1 && installed_packages+=("$pkg")
  done

  # Then uninstall the installed packages
  uninstall_pkgs "${installed_packages[@]}"

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
  echo "  -a, --all        Instead of passing each separate package as argument, you can use this"
  echo "                   to remove all packages from this git repository."
  echo "  -n, --nocommit   Don't commit changes on the git repository."
}

# Uninstall the packages from system
function uninstall_pkgs {
  test $# -gt 0 && sudo pacman -Rsc --noconfirm "$@"
}

# Remove a single package from this git repo
function remove_pkg_repo {
  local pkg=$1
  local nocommit=$2

  local pkg_path="${pkg_base_path:?}/$pkg"

  if ! [ -d "$pkg_path" ]; then
    error "Package $pkg not found."
    return 2
  fi

  remove_from_local_repo "$pkg" "$pkg_path"
  remove_from_git_repo "$pkg" "$pkg_path" "$nocommit"

  msg "Package $pkg removed."
}

function remove_from_local_repo {
  local pkg=$1 pkg_path=$2

  # Set the output folder of the built package
  export PKGDEST; PKGDEST="$(dirname "${repo_db:?}")"

  # Remove the package from the repo, if present
  test "$(get_repo_package_version "$pkg" "${repo_db:?}")" != "" && \
    repo-remove "${repo_db:?}" "$pkg"

  # Remove the built package files
  while IFS= read -r built_pkg_name; do
    test -f "$built_pkg_name" && rm "$built_pkg_name"
  done < <(cd "$pkg_path" && makepkg --packagelist)
}

function remove_from_git_repo {
  local pkg=$1 pkg_path=$2 nocommit=$3

  # Remove the git submodule completely
  git submodule deinit -f "$pkg_path"
  git rm -f "$pkg_path"
  rm -rf ".git/modules/$pkg_path"

  # Then commit that change
  test "$nocommit" = "false" && git commit -m ":fire: packages: remove $pkg"
}
