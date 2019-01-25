#!/usr/bin/env bash
#
# Update the repo containing the specified packages

function cmd::update {
  local pkgs=() updated_packages=0

  declare opt_all opt_nocommit opt__list
  parseopts "an" "all,nocommit" "$@" || exit 1
  cmd::update::validates_args "$@"

  # Read the packages from parameters or get all from the $pkg_base_path
  if $opt_all; then mapfile -t pkgs < <(list_pkgs); else pkgs=("${opt__list[@]}"); fi

  for pkg in "${pkgs[@]}"; do
    update_pkg "$pkg" "$opt_nocommit" && ((updated_packages+=1))
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
  echo "  -a, --all        Instead of passing each separate package as argument, you can use this"
  echo "                   to update all packages from this git repository."
  echo "  -n, --nocommit   Don't commit changes on the git repository."
}

# Update a git repository under the base package.
#
# Returns a success code if the repository has been updated.
function update_pkg {
  local pkg=$1 nocommit=$2

  local pkg_path="${pkg_base_path:?}/$pkg"

  if ! [ -e "$pkg_path" ]; then
    error "Package $pkg not found!"
    return 1
  fi

  # Signal 0 means "there has some changes, please rebuild"
  update_remote "$pkg" "$pkg_path" "$nocommit" && return 0
  update_upstream_vcs "$pkg" && return 0

  # Signal 2 means "no changes"
  return 2
}

function update_remote {
  local pkg=$1 pkg_path=$2 nocommit=$3

  # Let's not bother if that's not a git pkg
  test -e "$pkg_path/.git" || return 2

  msg "Checking for updates for $pkg"

  # Fetch from remote
  ( cd "$pkg_path" && git fetch origin )
  local current_ver; current_ver=$(cd "$pkg_path" && git rev-parse @)
  local remote_ver; remote_ver=$(cd "$pkg_path" && git rev-parse origin)

  # If versions are equal, no updates
  test "$current_ver" = "$remote_ver" && return 2

  # Ask before proceeding. Resets the branch first to avoid problems on merging. Ideally, submodule
  # repositories should never be changed locally.
  ask "New update for package $pkg. Continue?" || return 2
  ( cd "$pkg_path" && git reset --hard HEAD && git checkout master && git diff origin/master )

  # Confirm the diff before merging
  ask "Proceed?" || return 2
  ( cd "$pkg_path" && git merge origin/master )

  # Commit the update locally
  local current_ver; current_ver=$(cd "$pkg_path" && git rev-parse --short HEAD)
  test -z "$nocommit" && ( git add "$pkg_path" && git commit -m "$pkg: update to $current_ver" )

  # Signal that means "there has been changes, let's rebuild"
  return 0
}

function update_upstream_vcs {
  local pkg=$1

  # Updates on VCS packages are handled differently. Even if there are no changes on the PKGBUILD,
  # there might be changes on the VCS upstream repo, so we need to check if it has updates as well.
  is_vcs_package "$pkg" || return 2
  vcs_package_has_updates "$pkg" || return 2

  ask "New update on upstream for VCS package $pkg. Update?" && return 0 || return 2
}

function is_vcs_package {
  local pkg=$1
  local vcs_regex=".*-(bzr|git|hg|svn)$"

  [[ "$pkg" =~ $vcs_regex ]]
}

function vcs_package_has_updates {
  local pkg=$1

  local pkg_path="$pkg_base_path/$pkg"

  msg "Checking for VCS updates for $pkg..."

  # Get the current built version on the repo
  current=$(get_repo_package_version "$pkg" "${repo_db:?}")

  # Run makepkg to update the PKGBUILD pkgver
  ( cd "$pkg_path" && makepkg --nobuild --clean --cleanbuild --nocheck \
    --needed --rmdeps --noconfirm --noprogressbar > /dev/null 2>&1 )

  # Evaluates the PKGBUILD to get the version: It should have been changed by the makepkg above
  # Copied from https://github.com/AladW/aurutils/blob/master/lib/aur-srcver
  #
  # shellcheck disable=SC2016
  last=$(env -C "$pkg_path" -i bash -c '
    PATH= source PKGBUILD

    if [[ -v epoch ]]; then
      fullver=$epoch:$pkgver-$pkgrel
    else
      fullver=$pkgver-$pkgrel
    fi

    echo "$fullver"')

  # Clear all version changes done to the PKGBUILD by makepkg
  git_clean_repo "$pkg_path"

  test "$current" != "$last"
}
