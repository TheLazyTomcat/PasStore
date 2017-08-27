--------------------------------------------------------------------------------
                                  PasStore 1.x                                  
--------------------------------------------------------------------------------



Index
----------------------------------------
Content of this document divided into individual parts, with line numbers at
which each part starts.

  Index ...................................................  7
  Description ............................................. 23
  Project information ..................................... 34
  Installation ............................................ 45
  Licensing ............................................... 53
  Repositories ............................................ 72
  Authors, contacts ....................................... 84
  Copyright ............................................... 90



Description
----------------------------------------
PasStore is a simple program for password and/or login information storage.
The information is stored encrypted using a master password, but it probably is
not cryptographically secure. Full security was never a priority, since the 
program was developed only for personal use and to test different encryption and 
hashing methods, so be aware of this fact and use it carefully. 
As such, this program was not intended to be made public, but here it is. 



Project information
----------------------------------------
Program is primarily developed in Delphi 7 Personal and Lazarus 1.6.x (FPC 3.x). 
It should be possible to compile it in higher versions of Lazarus/FPC and 
possibly newer Delphi too. Code should be also compatible with older versions of 
Lazarus, namely Laz 1.4.x (FPC 2.6.4).
Project is configured in a way that you should be able to compile it without any
preparations. It is possible to compile it into both 32 bit and 64 bit binaries.



Installation
----------------------------------------
You don't need to install this program, just place it in any folder you have 
full access rights - the program will write a file (contains stored information) 
to this folder.



Licensing
----------------------------------------
Everything (source codes, executables/binaries, configurations, etc.), with few
exceptions mentioned below, is licensed under Mozilla Public License Version 
2.0. You can find full text of this license in file mpl_license.txt or on web 
page https://www.mozilla.org/MPL/2.0/.
Exception being following folders and their entire content:

./Documents

  This folder contains documents (texts, images, ...) used in creation of this
  program. Everything in this folder is licensed under the terms of Creative
  Commons Attribution-ShareAlike 4.0 (CC BY-SA 4.0) license. You can find full
  legal code in file CC_BY-SA_4.0.txt or on web page
  http://creativecommons.org/licenses/by-sa/4.0/legalcode. Short wersion is
  available on web page http://creativecommons.org/licenses/by-sa/4.0/.



Repositories
----------------------------------------
You can get actual copies of PasStore on either of these git repositories:

https://github.com/ncs-sniper/PasStore
https://bitbucket.org/ncs-sniper/passtore

Note - Master branch does not contain binaries, they can be found in a branch
       called bin (this branch will not be updated as often as master branch).



Authors, contacts
----------------------------------------
František Milt, frantisek.milt@gmail.com



Copyright
----------------------------------------
©2016-2017 František Milt, all rights reserved