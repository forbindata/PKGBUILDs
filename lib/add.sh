#!/usr/bin/env bash
#
# Add the specified packages to $pkg_base_path

function cmd::add {
  local pkgs=() added_packages=0

  declare opt_nocommit opt__list
  parseopts "n" "nocommit" "$@" || exit 1
  cmd::add::validates_args "$@"

  # Read the packages from parameters
  pkgs=("${opt__list[@]}")

  for pkg in "${pkgs[@]}"; do
    add_pkg "$pkg" "$opt_nocommit" && ((added_packages+=1))
  done

  if [ $added_packages -le 0 ]; then
    msg "No packages added."
  else
    msg "$added_packages package(s) added."
  fi
}

function cmd::add::validates_args {
  if [ "${#opt__list[@]}" -le 0 ]; then
    error "You need to specify at least one package in the arguments!"
    cmd::add::help
    exit 1
  fi
}


function cmd::add::help {
  echo ""
  echo "Usage: $0 add [OPTIONS] <URL> [<URL> ...]"
  echo ""
  echo "Adds the package(s) to the git repository. the <URL> parameter can be any URL in the"
  echo "following formats: https://, ssh:// or git://. If you want to add an AUR package, pass only"
  echo "the name and it will be assumed as an AUR repo."
  echo ""
  echo "Options:"
  echo "  -n, --nocommit   Don't commit changes on the git repository."
}

# Clones a git repo onto $pkg_base_path
function add_pkg {
  local url=$1
  local nocommit=$2

  msg "Adding $url"

  if is_package_installed "$url"; then
    msg2 "Package $url already installed, skipping..."
    return
  fi

  msg2 "Downloading PKGBUILD for $url"

  # If we're not using the absolute URL to the repo, then we assume it's AUR
  if ! [[ $url =~ ^(ssh|https):// ]]; then
    url="https://aur.archlinux.org/$url.git"
  fi

  show_pkgbuild "$url"
  ask "Continue?" || return 2

  ( cd "${pkg_base_path:?}" && git submodule add "$url" )

  test -z "$nocommit" && git commit -m ":sparkles: packages: add $pkg"

  msg "Added $pkg"
}

function is_package_installed {
  local url=$1 pkg_name=

  # If we're not using the absolute URL to the repo, then we assume it's AUR
  if ! [[ $url =~ ^(ssh|git|https):// ]]; then
    pkg_name=$1
  else
    pkg_name=$(echo "$url" | sed -E -e 's#(ssh|git|https)://.*/##' -e 's/\.git$//')
  fi

  test -e "$pkg_base_path/$pkg_name"
}

# Display the pkgbuild of a git repo.
# Currently it supports AUR, Github and generic SSH repos
function show_pkgbuild {
  local url=$1 repo_name=

  if [[ $url =~ aur\.archlinux\.org/.+\.git ]]; then
    repo_name=$(echo "$url" | sed -E 's#(https|ssh|git)?://##' | \
      grep -oP '(?<=aur\.archlinux\.org/).*(?=\.git)')

    # Show it on our editor!
    curl "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$repo_name" 2> /dev/null | \
      $EDITOR -R

  elif [[ $url =~ github\.com/\.+.git ]]; then
    repo_name=$(echo "$url" | sed -E 's#(https|ssh|git)?://##' | \
      grep -oP '(?<=github\.com/).*(?=\.git)')

    curl "https://raw.githubusercontent.com/$repo_name/master/PKGBUILD" 2> /dev/null | \
      $EDITOR -R

  elif [[ $url =~ ^(ssh|git):// ]]; then
    git archive --format=tar --remote="$url" master -- PKGBUILD | tar xf - | \
      $EDITOR -R

  else
    error "Could not get the PKGBUILD from this repo (URL not supported)."
    exit 1
  fi

  return 0
}
