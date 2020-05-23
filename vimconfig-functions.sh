#!/bin/bash

#-------------------#
# Utility functions #
#-------------------#

# Exit this script and display usage content along with some explanation message
exit_with_message() {
  echo "$1"
  usage; exit 1
}

# Run the provided command & arguments into dotvimconfig project's directory
run_in_project() {
  set -e
  pushd "$DOTVIM_CFG_DIR" > /dev/null
  trap "popd > /dev/null" EXIT
  "$@"
}

confirm() {
  REPLY=""
  question="${2:-$1}"
  prefix="${2+$1}"
  [ -n "$prefix" ] && echo -e "$prefix"
  while ! [[ $REPLY =~ ^[yn]$ ]]; do
    read -r -p "$question [y/n] "
  done
  [ "$REPLY" = y ] && return 0 || return 2
} 

# Ask the user for the deletion of the file or directory provided as argument:
# - If accepted, remove it and go on,
# - Otherwise, exit in error.
remove_or_abort() {
  if [ -e "$1" ]; then
    if confirm "Existing $1 detected..." "Override?"; then
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


#----------------------------------------------#
# Functions implementing dotvimconfig commands #
#----------------------------------------------#

# Initializes Vim configuration
dotvim_init() {
  # If this script isn't launched from ~/.vim dir, then force rebuilding 
  # ~/.vim from the actual dotvimconfig project directory
  echo "Init $HOME/.vim..."
  if ! [ "$DOTVIM_CFG_DIR" = "$(readlink -f "$HOME/.vim")" ] ; then
    remove_or_abort "$HOME/.vim"
    ln -s "$DOTVIM_CFG_DIR" "$HOME/.vim"
  fi
 
  # Erase existing .vimrc, and warn the user about it first
  echo "Init $HOME/.vimrc..."
  if ! [ -e "$HOME/.vimrc" ] || ! [ -L "$HOME/.vimrc" ] || \
	! [ "$DOTVIM_CFG_DIR/vimrc" = "$(readlink -f "$HOME/.vimrc")" ]; then
    remove_or_abort "$HOME/.vimrc"
    ln -s "$HOME/.vim/vimrc" "$HOME/.vimrc"
  fi

  # Add a symlink to this vimconfig.sh script onto $HOME/.local/bin
  echo "Install vimconfig command..."
  mkdir -p "$HOME/.local/bin" "$HOME/.local/share/bash-completion/completions"
  if ! [ -e "$HOME/.local/bin/vimconfig" ]; then
    ln -s "$HOME/.vim/vimconfig.sh" "$HOME/.local/bin/vimconfig"
  fi
  if ! [ -e "$HOME/.local/share/bash-completion/completions/vimconfig" ]; then
    ln -s "$HOME/.vim/vimconfig-completions.sh" "$HOME/.local/share/bash-completion/completions/vimconfig"
  fi

  echo "Download and/or update Vim plugins..."
  git submodule init
  git submodule update

  echo "Done! Enjoy viming :-)"
  echo "New Vim plugins can be configured through the vimconfig command"
  echo "(added to your \$PATH, under $HOME/.local/bin)"
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
    git commit -m "Install $plugin_name plugin as a submodule."
  fi
}

# Delete some Vim plugin from Vim configuration
# $1 : The name or URL of the plugin to remove
dotvim_remove() {
  plugin_name="$(to_bundle_name "$1")"

  if [ -d "bundle/$plugin_name" ]; then
    if confirm "Remove plugin $plugin_name?"; then
      git submodule deinit -f "bundle/$plugin_name"
      git rm "bundle/$plugin_name"
      git commit -m "Remove $plugin_name plugin from submodules list."
    fi
  else
    echo "The $plugin_name plugin does not exist under bundle/. Doing nothing..."
    return 2
  fi
}

# Update all registered Vim plugins at once
dotvim_update() {
  git submodule update
  git submodule foreach git pull origin master
  modified_modules="$(git status -s bundle/ | awk '{ sub(/.*\//, ""); print "- "$1 }')"
  printf '\n'
  if [ -z "$modified_modules" ]; then
    echo "No update found for any Vim plugin"
  elif confirm "Following Vim plugins have uncommitted changes:\n$modified_modules" "Commit these changes?"; then
    git add bundle/ && git commit -m "Updating Vim plugins"
  elif confirm "Rollback these changes?"; then
    for module in ${modified_modules//- /}; do git submodule update --checkout bundle/"$module"; done
  fi
}

# Reset all registered Vim plugins with new commits, one by one
dotvim_reset() {
  modified_modules="$(git status -s bundle/ | awk '{ sub(/.*\//, ""); print $1 }')"
  if [ -z "$modified_modules" ]; then
    echo "No plugin to reset."
  else
    for module in ${modified_modules//- /}; do
      if confirm "Rollback changes on plugin $module?"; then
	# ( cd bundle/$module; git checkout -- . )
	git submodule update --force --checkout bundle/"$module"
	echo "Commit message: [$(git --git-dir=.git/modules/bundle/"$module" log -1 --pretty=oneline | cut -d' ' -f2-)]."
      fi
    done
    echo "Done. No more plugin to reset."
  fi
}

