#!/bin/bash

function usage() {
  echo ""
  echo "Usage: vimconfig <init|add|update> [plugin-url]"
  echo ""
  echo "Detailed commands:"
  echo "******************"
  echo "vim init             -> Initializes Vim configuration"
  echo "vim add [plugin-url] -> Register a new Vim plugin into your configuration"
  echo "vim update           -> Update all registered Vim plugins at once"
  echo ""
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
  plugin_name=${url_parts[-1]}
  if [[ -d bundle/$plugin_name ]]; then
    echo "The $plugin_name plugin already exists under bundle/. Doing nothing..."
    exit 2
  else
    git submodule add $1 bundle/$plugin_name
    git add bundle/$plugin_name
    git commit -m "Install $plugin_name bundle as a submodule."
  fi
}

function update() {
  git submodule foreach git pull origin master
}


if [[ $# -gt 2 || ( $1 -ne 'add' && $# -gt 1 ) ]]; then
  usage

elif [[ $1 == 'init' ]]; then
  init

elif [[ $1 == 'add' ]]; then
  add $2

elif [[ $1 == 'update' ]]; then
  update

else
  usage
fi
  
