#!/usr/bin/env bash
#
# Build the specified packages

function cmd::build {
  local pkgs=() built_packages=0

  # Read the packages from parameters or get all from the $pkg_base_path
  if [ $# -gt 0 ]; then pkgs=("$@"); else mapfile -t pkgs < <(list_pkgs); fi

  for pkg in "${pkgs[@]}"; do
    build_pkg "$pkg" && ((built_packages+=1))
  done

  if [ $built_packages -le 0 ]; then
    success "No packages built."
  else
    success "$built_packages package(s) built."
  fi
}

# Build a single package
#
# Returns a success code when the build succeeds
function build_pkg {
  local pkg=$1

  local pkg_path="$pkg_base_path/$pkg"

  if ! test -e "$pkg_path"; then
    error "Package $pkg not found!"
    return 2
  fi

  # Set the output folder of the built package
  export PKGDEST; PKGDEST="$(dirname "$repo_db")"

  # Build the package
  ( cd "$pkg_path" && makepkg --clean --syncdeps --needed --noconfirm )

  # Stop if the build fails
  test $? -eq 0 || return 2

  # Create/update the .SRCINFO file on local packages
  if ! [ -e "$pkg_path/.git" ]; then
    ( cd "$pkg_path" && makepkg --printsrcinfo > .SRCINFO )

    # Commit the changed SRCINFO
    local changed; changed=$(git diff --name-only "$pkg_path/.SRCINFO" 2> /dev/null)
    if [ "$changed" != "" ]; then
      git add "$pkg_path/.SRCINFO"
      git commit -m ":package: $pkg: update .SRCINFO"
    fi
  else
    # When on submodule repositories, usually the build process leaves some files behind such as
    # caches or PKGBUILD version updates for VCS packages
    ( cd "$pkg_path" && git reset --hard HEAD && git clean -fd )
  fi

  # Add the package output to the pacman repo
  while IFS= read -r built_pkg_name; do
    repo-add --remove "$repo_db" "$built_pkg_name" 
  done < <(cd "$pkg_path" && makepkg --packagelist)

  return 0
}
