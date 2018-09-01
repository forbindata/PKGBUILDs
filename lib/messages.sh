#!/bin/sh
#
# Terminal messages output coloring
#
# This will try to output the messages as close as possible to the standard
# pacman messaage formatter.

# Print colorful notice messages to the console
normal="\\e[0m"
bold="\\e[1m"
blue="\\e[34m"
green="\\e[32m"
red="\\e[31m"
orange="\\e[33m"

# shellcheck disable=SC2059
error() { printf "${bold}${red}==> ERROR:${normal}${bold} ${*}${normal}\\n"; }

# shellcheck disable=SC2059
success() { printf "${bold}${green}==>${normal}${bold} ${*}${normal}\\n"; }

# shellcheck disable=SC2059
warn() { printf "${bold}${orange}==> WARNING:${normal}${bold} ${*}${normal}\\n"; }

# shellcheck disable=SC2059
info() { printf "${bold}${blue}  ->${normal}${bold} ${*}${normal}\\n"; }
