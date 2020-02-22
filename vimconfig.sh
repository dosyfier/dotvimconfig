#!/bin/bash

set -e

#---------------------------#
# Source external functions #
#---------------------------#

# Build this script's effective parent directory
# by resolving links and/or trailing ~
DOTVIM_CFG_SCRIPT_PATH="$0"
while [ -L "$DOTVIM_CFG_SCRIPT_PATH" ]; do
  DOTVIM_CFG_SCRIPT_PATH="$(readlink -f "$DOTVIM_CFG_SCRIPT_PATH")"
done
DOTVIM_CFG_DIR="$(realpath "$(dirname "${DOTVIM_CFG_SCRIPT_PATH/#\~/$HOME}")")"

# shellcheck source=vimconfig-functions.sh
source "$DOTVIM_CFG_DIR"/vimconfig-functions.sh


#-------------------#
# Utility functions #
#-------------------#

usage() {
  cat <<EOF

  Usage: vimconfig [OPTIONS] <command> [plugin-url/name]
  
  Detailed commands:
  ------------------
  vimconfig init                 -> Initializes Vim configuration
  vimconfig add [plugin-url]     -> Register a new Vim plugin into your configuration
  vimconfig remove [plugin-name] -> Delete some Vim plugin from your configuration
  vimconfig update               -> Update all registered Vim plugins at once
  vimconfig reset                -> Reset all registered Vim plugins with new commits, one by one
  
  Options:
  --------
  -h | -? | --help		 -> Display this message
  
  Examples:
  ---------
  vimconfig add https://github.com/tpope/vim-surround
  vimconfig remove vim-surround

EOF
}

# Parses all this script's arguments and sets DOTVIM_* global variables
parse_params() {
  while [ $# -ne 0 ]; do
    case "$1" in
      "-h"|"-?"|"--help")
	usage
	exit 0
	;;

      -*)
	exit_with_message "Unknown option: '$1'"
	;;

      *)
	if [ -z "$DOTVIM_COMMAND" ]; then
	  DOTVIM_COMMAND="$1"
	  if [[ "$1" =~ ^(init|update|reset)$ ]]; then
	    if [ -n "$2" ]; then
	      exit_with_message "Unexpected parameter for command '$DOTVIM_COMMAND'"
	    fi

	  elif [[ "$1" =~ ^(add|remove)$ ]]; then
	    if [ -z "$2" ]; then
	      exit_with_message "Missing plugin-url/name parameter for command '$DOTVIM_COMMAND'"
	    else
	      DOTVIM_PLUGIN="$2"
	      shift
	    fi

	  else
	    exit_with_message "Unknown command '$DOTVIM_COMMAND'"
	  fi

	else
	  exit_with_message "Wrong syntax on '$1'"
	fi
	;;
    esac
    shift
  done

  if [ -z "$DOTVIM_COMMAND" ]; then
    exit_with_message "No command argument specified."
  fi
}


#--------------#
# Main program #
#--------------#

parse_params "$@"
run_in_project "dotvim_$DOTVIM_COMMAND" "$DOTVIM_PLUGIN"

