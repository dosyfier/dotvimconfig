#!/bin/bash

usage() {
  cat <<EOF

  Usage: vimconfig [OPTIONS] <command> [plugin-url/name]
  
  Detailed commands:
  ------------------
  vimconfig init                 -> Initializes Vim configuration
  vimconfig add [plugin-url]     -> Register a new Vim plugin into your configuration
  vimconfig remove [plugin-name] -> Delete some Vim plugin from your configuration
  vimconfig update               -> Update all registered Vim plugins at once
  
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
	  if [[ "$1" =~ ^(init|update)$ ]]; then
	    if [ -n "$2" ]; then
	      exit_with_message "Unexpected parameter for command '$DOTVIM_COMMAND'"
	    fi

	  elif [[ "$1" =~ ^(add|remove)$ ]]; then
	    if [ -z "$2" ]; then
	      exit_with_message "Missing plugin-url/name parameter for command '$DOTVIM_COMMAND'"
	    else
	      DOTVIM_PLUGIN="$2"
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
}

# Exit this script and display usage content along with some explanation message
exit_with_message() {
  echo "$1"
  usage; exit 1
}

# Run the provided command & arguments into dotvimconfig project's directory
run_in_project() {
  set -e
  pushd "$HOME/.vim" > /dev/null
  trap "popd > /dev/null" EXIT
  "$@"
}

# Ask the user for the deletion of the file or directory provided as argument:
# - If accepted, remove it and go on,
# - Otherwise, exit in error.
remove_or_abort() {
  if [ -e "$1" ]; then
    echo "Existing $1 detected..."
    while ! [[ $REPLY =~ ^[yn]$ ]]; do
      read -r -p "Override? [y/n] "
    done
    if [ "$REPLY" = y ]; then
      rm -rf "$1"
    else
      return 2
    fi
  fi
}

# Parse the provided plugin URL to extract the plugin's Git repo name 
# and remove any trailing ".git" extension
to_bundle_name() {
  mapfile -t url_parts < <(echo "$1" | grep -Po '[^\/]+')
  echo "${url_parts[-1]/%.git/}"
}

# Initializes Vim configuration
dotvim_init() {
  # Build this script's effective parent directory
  # by resolving links and/or trailing ~
  # (using pwd since we are necessarily in dotvimconfig dir,
  # and because, due to run_in_project, '$(dirname $0)' would be wrong)
  real_dirname="$(readlink -f "$(pwd)")"
  real_dirname="${real_dirname/#\~/$HOME}"

  # If this script isn't launched from ~/.vim dir, then force rebuilding 
  # ~/.vim from the actual dotvimconfig project directory
  echo "Init $HOME/.vim..."
  if ! [ "$real_dirname" = "$(readlink -f "$HOME/.vim")" ] ; then
    remove_or_abort "$HOME/.vim"
    ln -s "$real_dirname" "$HOME/.vim"
  fi
 
  # Erase existing .vimrc, and warn the user about it first
  echo "Init $HOME/.vimrc..."
  if ! [ -e "$HOME/.vimrc" ] || ! [ -L "$HOME/.vimrc" ] || \
	! [ "$real_dirname/vimrc" = "$(readlink -f "$HOME/.vimrc")" ]; then
    remove_or_abort "$HOME/.vimrc"
    ln -s "$HOME/.vim/vimrc" "$HOME/.vimrc"
  fi

  echo "Download and/or update Vim modules..."
  git submodule init
  git submodule update

  echo "Done! Enjoy viming :-)"
}

# Register a new Vim plugin into Vim configuration
# $1 : New plugin's URL
dotvim_add() {
  plugin_name="$(to_bundle_name "$1")"

  if [ -d "bundle/$plugin_name" ]; then
    echo "The $plugin_name plugin already exists under bundle/. Doing nothing..."
    return 2
  else
    git submodule add "$1" "bundle/$plugin_name"
    git add "bundle/$plugin_name"
    git commit -m "Install $plugin_name bundle as a submodule."
  fi
}

# Delete some Vim plugin from Vim configuration
# $1 : The name or URL of the plugin to remove
dotvim_remove() {
  plugin_name="$(to_bundle_name "$1")"

  if [ -d "bundle/$plugin_name" ]; then
    git submodule deinit "bundle/$plugin_name"
    git rm "bundle/$plugin_name"
    git commit -m "Remove $plugin_name bundle from submodules list."
  else
    echo "The $plugin_name plugin does not exist under bundle/. Doing nothing..."
    return 2
  fi
}

# Update all registered Vim plugins at once
dotvim_update() {
  git submodule update
  git submodule foreach git pull origin master
}


# -- Main program -- #

parse_params "$@"
run_in_project "dotvim_$DOTVIM_COMMAND" "$DOTVIM_PLUGIN"

