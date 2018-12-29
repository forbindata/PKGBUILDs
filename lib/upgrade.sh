#!/usr/bin/env bash
#
# Seek all packages under the $pkg_base_path and look for updates. When there
# are, we update, build then install them.

function cmd::upgrade {
  local updated_pkgs=() built_pkgs=() failed_pkgs=()

  # Read the packages from parameters or get all from the $pkg_base_path
  test $# -gt 0 && pkgs=("$@") || pkgs=("$(list_pkgs)")

  for pkg in "${pkgs[@]}"; do
    update_pkg "$pkg" && updated_pkgs+=("$pkg")
  done

  if [ "${#updated_pkgs[@]}" -eq 0 ]; then
    success "No updates."
    exit
  else
    info "Updated packages: ${updated_pkgs[*]}"
  fi

  for pkg in "${updated_pkgs[@]}"; do
    build_pkg "$pkg" && built_pkgs+=("$pkg") || failed_pkgs+=("$pkg")
  done

  install_pkgs "${built_pkgs[@]}"

  # Then show the errors, if any
  if [ "${#failed_pkgs[@]}" -gt 0 ]; then
    error "Error while building the following packages: ${failed_pkgs[*]}"
    exit 1
  fi
}
