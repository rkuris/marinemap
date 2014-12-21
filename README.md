marinemap
=========

I got pretty tired of paying Garmin for maps that are only updated annually. Fortunately, the USGS produces
S-57 marine maps on a regular basis. However, there was no tool to convert these into a gmapsupp that the Garmin
could use.

There were some things that did some of it, there are libraries to read S-57 stuff and there are ways of taking
openstreetmap XML and making garmin files out of them, but nothing to put it all together.

So here's a script I used to generate charts for California. If you're elsewhere, I'm sure you can make this work
with other ENC files.

What you'll need
----------------
1. java7
2. mkgmap
3. ogr2ogr

Running it
----------
    perl perl/main.pl EncFile.000 ...
    rm -f gmapsupp.img osmmap.img
    mkgmap --gmapsupp *.img

Then copy the resulting gmapsupp.img to your gramin. Note that you can add other maps if you want to have land stuff; the
land information is not taken from the S-57


References
----------
https://github.com/albertz/navit/blob/master/navit/map/garmin/garmintypes.txt
