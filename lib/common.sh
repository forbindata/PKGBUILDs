#!/usr/bin/env bash
#
# Common library functions

# Print colorful notice messages to the console
readonly normal="\\e[0m"
readonly bold="\\e[1m"
readonly blue="\\e[34m"
readonly green="\\e[32m"
readonly red="\\e[31m"
readonly orange="\\e[33m"

# shellcheck disable=SC2059
error() { printf "${bold}${red}==> ERROR:${normal}${bold} ${*}${normal}\\n" 1>&2; }

# shellcheck disable=SC2059
success() { printf "${bold}${green}==>${normal}${bold} ${*}${normal}\\n"; }

# shellcheck disable=SC2059
warn() { printf "${bold}${orange}==> WARNING:${normal}${bold} ${*}${normal}\\n"; }

# shellcheck disable=SC2059
info() { printf "${bold}${blue}  ->${normal}${bold} ${*}${normal}\\n"; }

# shellcheck disable=SC2059
ask() {
  printf "${bold}${blue}  ->${normal}${bold} ${*}${normal} [Yn] "
  read -rp "" answer
  case ${answer:0:1} in
    n|N) return 1 ;;
    *) return 0 ;;
  esac
}

# Get the packages passed as argument or all packages under $pkg_base_path
function list_pkgs {
  ( cd "$pkg_base_path" && ls )
}
