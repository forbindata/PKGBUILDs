#!/usr/bin/env bash
#
# Build the specified packages

function cmd::build {
  local pkgs=() built_packages=0

  declare opt_all opt_install opt_force opt_no_cleanup opt__list
  parseopts "aif-" "all,install,force,no-cleanup" "$@" || exit 1
  cmd::build::validates_args "$@"

  # Read the packages from parameters or get all from the $pkg_base_path
  if $opt_all; then mapfile -t pkgs < <(list_pkgs); else pkgs=("${opt__list[@]}"); fi

  for pkg in "${pkgs[@]}"; do
    build_pkg "$pkg" "$opt_force" "$opt_no_cleanup" && ((built_packages+=1))
  done

  if [ $built_packages -le 0 ]; then
    msg "No packages built."
    return
  elif [ $built_packages -lt ${#pkgs[@]} ]; then
    error "Some package(s) could not be built. Please, check the logs."
    return 1
  fi

  if $opt_install && ! install_pkgs "$opt_force" "${pkgs[@]}"; then
    error "Installation failed. Please check the logs."
    return 1
  fi

  if $opt_install; then
    msg "$built_packages package(s) built and installed successfully!"
  else
    msg "$built_packages package(s) built."
  fi
}

function cmd::build::validates_args {
  validates_all_or_package_argument_list "cmd::build::help" "$opt_all" "${#opt__list[@]}"
}

function cmd::build::help {
  echo ""
  echo "Usage: $0 build [OPTIONS] [<PKG> ...]"
  echo ""
  echo "Builds the specified PKGs."
  echo ""
  echo "Options:"
  echo "  -a, --all       Instead of passing each separate package as argument, you can use this"
  echo "                  to build all packages from this git repository."
  echo "  -i, --install   After building all specified packages, install them with $0 install."
  echo "  -f, --force     Force building a package, even if it's been built."
  echo "  --no-cleanup    Don't cleanup the git repository after building. This is useful when you"
  echo "                  are building a package that is not directly included on the git repo, but"
  echo "                  on a submodule and you own it (e.g. an AUR package)."
}

# Build a single package
#
# Returns a success code when the build succeeds
function build_pkg {
  local pkg=$1
  local force=$2
  local no_cleanup=$3

  local pkg_path="${pkg_base_path:?}/$pkg"

  if ! test -e "$pkg_path"; then
    error "Package $pkg not found!"
    return 2
  fi

  # Set the output folder of the built package
  export PKGDEST; PKGDEST="$(dirname "${repo_db:?}")"

  # Build the package
  test "$force" = "true" && local force_param="--force"
  msg "Building package $pkg"
  ( cd "$pkg_path" && makepkg --clean --syncdeps --needed --noconfirm $force_param )

  # Stop if the build failed
  test $? -eq 0 || return 2

  # Add the package output to the pacman repo
  while IFS= read -r built_pkg_name; do
    repo-add --remove "$repo_db" "$built_pkg_name"
  done < <(cd "$pkg_path" && makepkg --packagelist)

  # Create/update the .SRCINFO file on local packages
  if ! [ -e "$pkg_path/.git" ]; then
    ( cd "$pkg_path" && makepkg --printsrcinfo > .SRCINFO )

    # Commit the changed SRCINFO
    local changed; changed=$(git diff --name-only "$pkg_path/.SRCINFO" 2> /dev/null)
    if [ "$changed" != "" ]; then
      git add "$pkg_path/.SRCINFO"
      is_vcs_package "$pkg" && git add "$pkg_path/PKGBUILD"
      git commit -m "$pkg: update .SRCINFO"
    fi
  else
    # When on submodule repositories (non local package), usually the build process leaves some
    # files behind such as caches or PKGBUILD version updates for VCS packages, so we will clean it
    # up. Unless we say we don't want that.
    test "$no_cleanup" = "false" && git_clean_repo "$pkg_path"
  fi

  # This line helps to separate when there are multiple packages being built
  echo

  return 0
}
