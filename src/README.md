=========================
Domogik installer sources
=========================

IMPORTANT NOTICE
================

You must not edit directly the install scripts in the root folder of this repository! They are built thanks to the sources from the current directory.

Build the scripts
=================

Just run :

``` 
./build.sh
```

The installation scripts are built in the root folder of this repository.

Tree
====

```
install-develop.sh            # installer for the release in development.
install-<release>.sh          # installer for a given release.
src/                          # for developpers only : the sources of the installer scripts.
src/build.sh                  # the script that build the final installer scripts
src/build/                    # the folder used by the building process
src/templates/               
src/templates/install-*tpl    # the templates of the installation scripts
src/templates/_include/*      # some functions to include in the the installation scripts          
src/templates/_dependencies/* # the commands that install dependencies for the various linux distributions
```
