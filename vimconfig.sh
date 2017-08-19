#!/bin/bash

function usage() {
  cat <<EOF

Usage: vimconfig <init|add|update> [plugin-url]

Detailed commands:
******************
vimconfig init                 -> Initializes Vim configuration
vimconfig add [plugin-url]     -> Register a new Vim plugin into your configuration
vimconfig remove [plugin-name] -> Delete some Vim plugin from your configuration
vimconfig update               -> Update all registered Vim plugins at once

Examples:
*********
vimconfig add https://github.com/tpope/vim-surround
vimconfig remove vim-surround

EOF
}

function init() {
  [[ -f ~/.vimrc ]] && rm -f ~/.vimrc
  ln -s ~/.vim/vimrc ~/.vimrc
  cd ~/.vim
  git submodule init
  git submodule update
}

function add() {
  url_parts=(`echo $1 | grep -Po '[^\/]+'`)
  plugin_name=${url_parts[-1]/%.git/}
  if [[ -d bundle/$plugin_name ]]; then
    echo "The $plugin_name plugin already exists under bundle/. Doing nothing..."
    exit 2
  else
    git submodule add $1 bundle/$plugin_name
    git add bundle/$plugin_name
    git commit -m "Install $plugin_name bundle as a submodule."
  fi
}

function remove() {
  if [[ -d bundle/$1 ]]; then
    git submodule deinit bundle/$1
    git rm bundle/$1
    git commit -m "Remove $1 bundle from submodules list."
  else
    echo "The $1 plugin does not exist under bundle/. Doing nothing..."
    exit 2
  fi
}

function update() {
  git submodule foreach git pull origin master
}


if [[ $1 == 'init' && $# -eq 1 ]]; then
  init

elif [[ $1 == 'add' && $# -eq 2 ]]; then
  add $2

elif [[ $1 == 'remove' && $# -eq 2 ]]; then
  remove $2

elif [[ $1 == 'update' && $# -eq 1 ]]; then
  update

else
  usage
fi

