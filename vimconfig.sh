#!/bin/bash

function usage() {
  echo "Usage: vimconfig <init|add|update>"
}

function init() {
  [[ -f ~/.vimrc ]] && rm -f ~/.vimrc
  ln -s ~/.vim/vimrc ~/.vimrc
  cd ~/.vim
  git submodule init
  git submodule update
}

function add() {
  plugin_name=${1/*\//}
  git submodule add $1 bundle/$plugin_name
  git add .
  git commit -m "Install $plugin_name bundle as a submodule."
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
  
