#!/usr/bin/env bash
#
# Common library functions

# Use Pacman's message formatter
# This gives us the following functions for free:
# plain, msg, msg2, warning & error
source /usr/share/makepkg/util/message.sh
[[ -t 2 && ! -o xtrace ]] && colorize

# This function will wait on user input to do some action. It returns failure when the user chooses
# a negative answer.
#
# Arguments
#   1 - The string of the question you want to ask.
#
# shellcheck disable=SC2059
function ask {
  printf "${BOLD}${BLUE}  ->${ALL_OFF}${BOLD} ${*}${NORMAL} [Yn] "
  read -rp "" answer
  case ${answer:0:1} in
    n|N) return 1 ;;
    *) return 0 ;;
  esac
}

# Get the packages passed as argument or all packages under $pkg_base_path
function list_pkgs {
  ( cd "${pkg_base_path:?}" && ls )
}

# This is a common validation scenario for most of the commands in this lib. Usually, the user
# either needs to pass --all to match all installed packages or specify them one by one.
#
# Arguments
#   1 - The help function that we want to call if the validation fails
#   2 - The opt_all flag (--all arg) - true or false
#   3 - The amount of arguments (package names) that the CLI received
function validates_all_or_package_argument_list {
  local help_function=$1
  local opt_all=$2
  local amount=$3

  if [ "$amount" -ge 1 ] && $opt_all; then
    error "You can't specify --all and a package list!"
    $help_function
    exit 1
  elif [ "$amount" -eq 0 ] && ! $opt_all; then
    error "You must specify either a package list or --all"
    $help_function
    exit 1
  fi
}

# Clean a git repository to its HEAD and remove any untracked content
# Be careful not to run this on the main repo or it will revert all uncommited changes
function git_clean_repo {
  local path=$1

  # Ignore if it's not a git folder. Safety lock against destructive operation on non desirable
  # directories.
  ! test -e "$path/.git" && return 0

  msg2 "Cleaning up git repo $path..."
  ( cd "$path" && git reset --hard HEAD > /dev/null && git clean -ffd > /dev/null )
}

# Get the current built version of that package on the repo
function get_repo_package_version {
  local pkg=$1
  local repo_path=$2

  repo_file=$(basename "$repo_path")
  repo_name=${repo_file%%.*}
  pacman -Sl "$repo_name" | awk '{ print $2":"$3 }' | grep "^$pkg:" | sed 's/^.*://'
}

# Parses the options using getopt. This currently only works with boolean parameters, and you need
# to specify both the short and long option names for them. Don't run this on a subshell or it won't
# work. When parsing a parameter, it will set a global variable named opt_<your_long_opt_name> with
# a boolean telling whether that parameter were assigned or not on the CLI. See the examples below.
#
# Example usage:
#
# parseopts "ia" "install,all" "$@"
#
# Then, calling your program like this:
#
# $ ./my-program -i
#
# Will set a global variable named $opt_install to true. The same thing would happen if you pass the
# long name version of that option:
#
# $ ./my-program --all
#
# Then a global variable $opt_all would be set to true. The variable $opt_install would be set to
# false
#
# Lastly, it sets a array parameter named $opt__list with all the parameters that doesn't fit on a
# option, like below:
#
# $ ./my-program --install this-app "that app"
#
# This will set the following variables:
#
# $opt_install = true
# $opt_all = false
# $opt__list = ("this-app", "that app")
#
# Extra: Yes, it handles spaces nicely!
# Extra: If you need a multiple-word option that doesn't match a single-letter option, use a dash
#        as the matching character for that option.
function parseopts {
  local options=$1; shift
  local longopts=$1; shift

  local parsed; parsed=$(getopt --options="$options" --longoptions="$longopts" --name "$0" -- "$@")
  test $? -ne 0 && return 2

  eval set -- "$parsed"

  # Create array from $longopts
  IFS=',' read -r -a longopts_arr <<< "$longopts"

  # Iterate to set all values false
  for opt in "${longopts_arr[@]}"; do
    eval "opt_${opt//-/_}"=false
  done

  while true; do
    # Break out of the loop as soon as the -- is seen
    test "$1" == "--" && break

    local i=0
    for opt in "${longopts_arr[@]}"; do
      if [ "$1" == "-${options:$i:1}" ] || [ "$1" == "--$opt" ]; then
        eval "opt_${opt//-/_}"=true
        break
      fi

      ((i+=1))
    done

    shift
  done

  # Remove the last '--' parameter from the $@
  shift

  # Set the rest of the parameters to an array so we don't need to figure where on $@ we can start
  # reading from (on programs that need other parameters)
  # shellcheck disable=2034
  opt__list=("$@")
}
