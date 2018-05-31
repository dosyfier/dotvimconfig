#!/bin/bash

usage() {
  cat <<EOF

Usage: vimconfig [OPTIONS] <init|add|update> [plugin-url]

Detailed commands:
------------------
vimconfig init                 -> Initializes Vim configuration
vimconfig add [plugin-url]     -> Register a new Vim plugin into your configuration
vimconfig remove [plugin-name] -> Delete some Vim plugin from your configuration
vimconfig update               -> Update all registered Vim plugins at once

Options:
--------
-h | --help  -> Display this message

Examples:
---------
vimconfig add https://github.com/tpope/vim-surround
vimconfig remove vim-surround

EOF
}

# Run the provided command & arguments into dotvimconfig project's directory
run_in_project() {
  set -e
  pushd "$(dirname $0)" > /dev/null
  trap "popd > /dev/null" EXIT
  $@
}

# Ask the user for the deletion of the file or directory provided as argument:
# - If accepted, remove it and go on,
# - Otherwise, exit in error.
remove_or_abort() {
  if [ -e "$1" ]; then
    echo "Existing $1 detected..."
    while ! [[ $REPLY =~ ^[yn]$ ]]; do
      read -p "Override? [y/n] " -r
    done
    if [ $REPLY = y ]; then
      rm -rf "$1"
    else
      return 2
    fi
  fi
}

# Initializes Vim configuration
init() {
  # Build this script's effective parent directory
  # (using pwd since we are necessarily in dotvimconfig dir,
  # and because, due to run_in_project, '$(dirname $0)' would be wrong)
  real_dirname="`pwd`"

  # If this script isn't launched from ~/.vim dir, then force rebuilding 
  # ~/.vim from the actual dotvimconfig project directory
  echo "Init $HOME/.vim..."
  if ! [ "$real_dirname" = "$HOME/.vim" ] ; then
    remove_or_abort "$HOME/.vim"
    ln -s "$real_dirname" "$HOME/.vim"
  fi
 
  # Erase existing, and warn the user about it first
  echo "Init $HOME/.vimrc..."
  remove_or_abort "$HOME/.vimrc"
  ln -s $HOME/.vim/vimrc $HOME/.vimrc

  echo "Download and/or update Vim modules..."
  git submodule init
  git submodule update

  echo "Done! Enjoy viming :-)"
}

# Register a new Vim plugin into Vim configuration
add() {
  # Parse the provided plugin URL to extract the plugin's Git repo name 
  # and remove any trailing ".git" extension
  url_parts=(`echo $1 | grep -Po '[^\/]+'`)
  plugin_name=${url_parts[-1]/%.git/}

  if [ -d bundle/$plugin_name ]; then
    echo "The $plugin_name plugin already exists under bundle/. Doing nothing..."
    return 2
  else
    git submodule add $1 bundle/$plugin_name
    git add bundle/$plugin_name
    git commit -m "Install $plugin_name bundle as a submodule."
  fi
}

# Delete some Vim plugin from Vim configuration
remove() {
  if [ -d bundle/$1 ]; then
    git submodule deinit bundle/$1
    git rm bundle/$1
    git commit -m "Remove $1 bundle from submodules list."
  else
    echo "The $1 plugin does not exist under bundle/. Doing nothing..."
    return 2
  fi
}

# Update all registered Vim plugins at once
update() {
  git submodule update
  git submodule foreach git pull origin master
}


# -- Main program -- #

command=$1
if [[ $command =~ (-h|--help) ]]; then
  usage
  exit 0
elif [ -z $command ] || ! [[ $command =~ (init|add|remove|update) ]] \
  || [ $# -gt 2 ] || ( ! [[ $command =~ (add|remove) ]] && [ $# -gt 1 ] ); then
  usage
  exit 1
else
  run_in_project $@
fi

