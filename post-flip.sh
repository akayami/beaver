#!/bin/bash
PROJECT_HOME=$1;


sudo ln -f -s $PROJECT_HOME/bvrctl.sh /usr/bin/bvrctl.sh
sudo ln -f -s $PROJECT_HOME/bvrdpl.sh /usr/bin/bvrdpl.sh
sudo ln -f -s $PROJECT_HOME/bvrflip.sh /usr/bin/bvrflip.sh	