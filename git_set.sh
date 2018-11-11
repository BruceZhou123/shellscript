#!/bin/bash

git config --global user.name "BruceZhou123"
git config --global user.email 2731760609@qq.com
git config --global core.excludesfile ~/.gitignore
cd ~/
wget https://github.com/github/gitignore/blob/master/Python.gitignore
mv Python.gitignore .gitignore
