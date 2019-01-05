#!/usr/bin/env bash
#
# Update the repo containing the specified packages

function cmd::update {
  local pkgs=() updated_packages=0

  declare opt_all opt__list
  parseopts "a" "all" "$@" || exit 1
  cmd::update::validates_args "$@"

  # Read the packages from parameters or get all from the $pkg_base_path
  if $opt_all; then mapfile -t pkgs < <(list_pkgs); else pkgs=("${opt__list[@]}"); fi

  for pkg in "${pkgs[@]}"; do
    update_pkg "$pkg" && ((updated_packages+=1))
  done

  if [ $updated_packages -le 0 ]; then
    msg "No updates."
  else
    msg "$updated_packages package(s) updated."
  fi
}

function cmd::update::validates_args {
  validates_all_or_package_argument_list "cmd::update::help" "$opt_all" "${#opt__list[@]}"
}

function cmd::update::help {
  echo ""
  echo "Usage: $0 update [OPTIONS] [<PKG> ...]"
  echo ""
  echo "Update the specified PKGs by pulling the remote git submodule."
  echo ""
  echo "Options:"
  echo "  -a, --all       Instead of passing each separate package as argument, you can use this"
  echo "                  to update all packages from this git repository."
}

# Update a git repository under the base package.
#
# Returns a success code if the repository has been updated.
function update_pkg {
  local pkg=$1
  local pkg_path="${pkg_base_path:?}/$pkg"

  if ! [ -e "$pkg_path" ]; then
    error "Package $pkg not found!"
    return 1
  fi

  # Let's not bother if that's not a git pkg
  test -e "$pkg_path/.git" || return 2

  # Get from remote
  ( cd "$pkg_path" && git fetch origin )
  local current_ver; current_ver=$(cd "$pkg_path" && git rev-parse @)
  local remote_ver; remote_ver=$(cd "$pkg_path" && git rev-parse origin)

  # Return early if no updates for non-VCS packages
  ! is_vcs_package "$pkg" && test "$current_ver" = "$remote_ver" && return 2

  # Updates on VCS packages are handled differently. Even if there are no
  # changes on the PKGBUILD, there might be changes on the VCS upstream repo,
  # so we need to check if it has updates as well.
  if is_vcs_package "$pkg"; then
    vcs_package_has_updates "$pkg" || return 2

    ask "New update on upstream for VCS package $pkg. Update?" && \
      return 0 || return 2
  fi

  # Ask before proceeding. Resets the branch beforehand to avoid problems on
  # merging. Ideally submodule repositories should not be changed locally.
  ask "New update for package $pkg. Continue?" || return 2
  ( cd "$pkg_path" && git reset --hard HEAD && git diff origin/master )

  # Show diff before merging
  ask "Proceed?" || return 2
  ( cd "$pkg_path" && git merge origin/master && git rev-parse --short HEAD )

  # Commit the update locally
  local current_ver; current_ver=$(cd "$pkg_path" && git rev-parse --short HEAD)
  ( git add "$pkg_path" && git commit -m "$pkg: update to $current_ver" )

  # Signal that means "there has been changes"
  return 0
}

function is_vcs_package {
  local pkg=$1
  local vcs_regex=".*-(bzr|git|hg|svn)$"

  [[ "$pkg" =~ $vcs_regex ]]
}

function vcs_package_has_updates {
  local pkg=$1

  local pkg_path="$pkg_base_path/$pkg"

  # Evaluates the PKGBUILD to get the version
  # Copied from https://github.com/AladW/aurutils/blob/master/lib/aur-srcver
  #
  # shellcheck disable=SC2016
  function _get_current_vcs_version {
    env -C "$pkg_path" -i bash -c '
    PATH= source PKGBUILD

    if [[ -v epoch ]]; then
      fullver=$epoch:$pkgver-$pkgrel
    else
      fullver=$pkgver-$pkgrel
    fi

    echo "$fullver"
    '
  }

  # Get the current version
  current=$(_get_current_vcs_version)

  # Run makepkg to update the PKGBUILD pkgver
  ( cd "$pkg_path" && makepkg --nobuild --clean --cleanbuild --nocheck \
    --needed --rmdeps --noconfirm --noprogressbar > /dev/null 2>&1 )

  # Now get the version again: it should have been updated, if changed
  last=$(_get_current_vcs_version)

  # Clear all version changes done to the PKGBUILD by makepkg
  git_clean_repo "$pkg_path" 

  test "$current" != "$last"
}
