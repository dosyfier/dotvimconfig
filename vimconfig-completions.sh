#!/bin/bash

#---------------------------#
# Source external functions #
#---------------------------#

# shellcheck source=vimconfig-functions.sh
source "$HOME/.vim/vimconfig-functions.sh"


#-----------------------#
# Set up autocompletion #
#-----------------------#

complete_dotvimconfig()  {
  # Avoid completions if at least one argument has already been typed
  if [ "${#COMP_WORDS[@]}" == "2" ]; then
    # Produce completion reply based on available functions with name starting with "dotvim_"
    complete_words="$(compgen -A function | grep -E '^dotvim_' | sed 's,^dotvim_,,g')"
    COMPREPLY=($(compgen -W "$complete_words" -- "${COMP_WORDS[1]}"))

  elif [ "${#COMP_WORDS[@]}" == "3" ] && [ "${COMP_WORDS[1]}"  == "remove" ]; then
    # If "remove" function has been typed, then propose the list of installed Vim plugins
    plugin_list="$(ls -1 "$HOME"/.vim/.git/modules/bundle/)"
    COMPREPLY=($(compgen -W "$plugin_list" -- "${COMP_WORDS[2]}"))

  else
    return
  fi

}

complete -F complete_dotvimconfig vimconfig

