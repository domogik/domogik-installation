#!/bin/bash
################################################################################
#                                                                              #
#                          Build script for :                                  #
#                                                                              #
#                      Domogik installation script                             #
#                                                                              #
#                      ~~~~~~ www.domogik.org ~~~~~                            #
#                                                                              #
################################################################################
#
# This script will automatically :
# - build the installation script
#
################################################################################

BUILD_INFORMATIONS=$(date "+%Y-%m-%d %H:%M")
ROOT_FOLDER=$(dirname $0)
mkdir -p $ROOT_FOLDER/build/
staticjinja build --outpath $ROOT_FOLDER/build/ \
                  --srcpath $ROOT_FOLDER/templates/

for fic in $ROOT_FOLDER/build/install*tpl
  do
    newfic=$(basename $fic | sed "s/tpl/sh/") 
    echo "Move '$fic' as '$ROOT_FOLDER/../$newfic' and in the same time, update its build informations..."
    #cp -f $fic $ROOT_FOLDER/../$newfic
    sed "s/%% build_informations %%/$BUILD_INFORMATIONS/" $fic >  $ROOT_FOLDER/../$newfic
done

