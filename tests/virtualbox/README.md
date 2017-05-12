VM preparation
==============

Debian
------

* Get the raw image
* Install build-essentials
* Install linux headers
* Install Virtualbox guest additions
* Install Openssh server
* Allow root login over ssh : 'PermitRootLogin yes'


Snapshots
=========

The snapshot to use for the installation tests must be named "step0"



Help
====

To stop a running VM : 

    VBoxManage controlvm  TheVMName poweroff
