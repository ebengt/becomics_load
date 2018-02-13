# becomics_load

Companion to Becomics.
Download from/upload to becomics, using a text file.
File contents must be lines with:
URL\t# Name\tcomic_update_day\tDay1,Day2...

If this is an upload and only the # is present (ie, Name is missing), the program will invent a Name from the URL.

It is possible to get a better example by adding an entry to Becomics manually and download it.

Usage description when started without any argument.

## Installation

mix deps.get
mix test
mix escript.build
cp becomics_load $HOME/bin/becomics_load
