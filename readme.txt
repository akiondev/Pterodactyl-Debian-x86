Star Wars Jedi Academy dedicated server for Linux.
Version 1.011
(this server version will only host JA games patched to 1.01)
(You must have the new patch assets from jkacademy1_01.exe installed!)

-history
1.011 synch up with retail 1.01 patch
1.01  Minor update to fix faulty rand() calls.


With much gratitude to James Drews for compiling this 
and sorting out the problems.


This archive file contains:
  readme.txt               : The file your reading now
  server options.txt       : List of server options
  linuxjampded             : Jedi Academy linux binary
  jampgamei386.so          : The game VM shared library
  libcxa.so.1              : shared library needed by the game binary
  server.cfg               : an example server config file
  Disclaimer-Jedi Academy Dedicated Server.rtf : Legal Disclaimer.

Install instructions:

On your linux box:
-Create a directory for the game. example: 
    mkdir /usr/local/games/ja
-Copy the linux binary into this directory
-Mark the file as executable. example:
    chmod a+x /usr/local/games/ja/linuxjampded
-Create the 'base' directory. example:
     mkdir /usr/local/games/ja/base
   Note, YES, it is case sensitive and the program will look for all lower case
-Copy the files from the base directory of the retail CD into the
   base directory you just created. In particular, the assets0.pk3, assets1.pk3 and assets2.pk3
   Yes, you need all of them...
-Copy the libcxa.so.1 to your lib directory if it doesn't already have it. Example:
     cp libcxa.so.1 /usr/lib

Running the dedicated server:

-"cd" into the game directory (cd /usr/local/games/ja)
-Run the binary. An example is:
    ./linuxjampded +exec server.cfg

This example assumes you have created a configuration file called server.cfg and placed
it into the "base" directory. An example server.cfg file is included with this 
distribution. You should modify it first before using it.

By default, the server will run in "internet" play mode and advertise its presense to 
the master server. If you wish to have a LAN play only server, change your server 
config to set dedicated 1, or change the command line to be:
    ./linuxjampded +set dedicated 1 +exec server.cfg


Notes:
-The game will look in the base directory or home directory of the user running the 
  program (~/.ja/)
-If you set the logfile option to 1, the files will be stored in your user
  home directory in ~/.ja/base/
-Running the linuxjampded binary under FreeBSD use
   brandelf -t Linux /usr/local/games/ja/linuxjampded
-If you are running the server behind a NAT box, any client machine also behind
 that NAT box will not be able to see the server listed in the "internet" list.
 Switch to the local lan setting instead.


© 2003 LucasArts Entertainment Company LLC, © 2003 Lucasfilm Ltd 
& ™ or ® as indicated. All rights reserved. Used Under Authorization. 
LucasArts and the LucasArts logo are registered trademarks of Lucasfilm Ltd. 
Activision is a registered trademark of Activision, Inc. © 2003 Activision, Inc. 
This product contains software technology licensed from Id Software, Inc. Id Technology © 1999-2003 Id Software, Inc. 
All other trademarks and trade names are the properties of their respective owners.