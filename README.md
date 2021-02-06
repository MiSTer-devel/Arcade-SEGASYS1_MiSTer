# [Arcade: SEGA System 1](https://www.system16.com/hardware.php?id=693) for [MiSTer](https://github.com/MiSTer-devel/Main_MiSTer/wiki) 

by [MiSTer-X](https://twitter.com/mrx_8b)

## Specifications

* T80/T80s - Version : 0242
* Z80 compatible microprocessor core - Copyright (c) 2001-2002 Daniel Wallner (jesus@opencores.org)
* 2020/01/08  Impl. Trigger 3  (for SEGA Ninja)

## Supported Games

Currently implemented:

* 4-D Warriors
* Block Gal
* Bullfight
* Flicky
* I'm Sorry
* Mister Viking
* My Hero
* Pitfall II
* Rafflesia
* Regulus
* Sega Ninja
* Spatter
* Star Jacker
* Swat
* TeddyBoy Blues
* Up'n Down
* Water Match
* Wonder Boy

Sega System 1 games currently **not yet** implemented:

* Choplifter
* Gardia
* Noboranka / Zippy Bug

## ROM Files Instructions

**ROMs are not included!** In order to use this arcade core, you will need to provide the correct ROM file yourself.

Find this zip file somewhere. You need to find the file exactly as required. Check the .mra file in a text editor for more information.  
Do not rename other zip files even if they also represent the same game - they are not compatible!  
The name of zip is taken from M.A.M.E. project, so you can get more info about hashes and contained files there.

How to install:
1. Update MiSTer binary to v200106 or later
2. copy releases/*.mra to /media/fat/_Arcade
3. copy releases/*.rbf to /media/fat/_Arcade/cores
4. copy ROM zip files  to /media/fat/_Arcade/mame

Be sure to use the MRA file in "releases" of this repository.  
It does not guarantee the operation when using other MRA files.
