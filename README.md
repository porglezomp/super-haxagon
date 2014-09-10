Super Haxagon
=============

A Mac application to automatically play Super Hexagon for you.
It's not intended as a cheating tool (although it can be used that way),
it is being developed primarily as a learning excercise, and also so that
I can get the levels I beat on my iPod beat on the computer.

Usage
-----

Run Super Hexagon and then run Super Haxagon, and it will beat the game for you.

Building
--------

The code should build directly in XCode with no special dependencies.

How it Works
------------

The application reads out of the screen buffer, and uses only information
available on the screenin order to synthesize keypresses. It doesn't require
any special access to Super Hexagon, will only work while the game is in the
foreground, and can be messed up by someone intervening.

Colophon
--------

Created by Caleb Jones
