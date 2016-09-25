#!/bin/bash

width_in_tiles=$1
height_in_tiles=$2
url_template=$3

export TMPDIR=$(mktemp --directory)

filelist=""
for y in $(seq $height_in_tiles)
do
  for x in $(seq $width_in_tiles)
  do
    url=$(echo $url_template | sed "s/%X/$x/" | sed "s/%Y/$y/")

    outfile="$TMPDIR"/tile"$x"_"$y".jpg
    mkfifo "$outfile"
    wget -O "$outfile" "$url" 2>/dev/null &
    filelist="$filelist $outfile"

    echo -ne "Starting download of tile $x:$y    \r"
  done
done

echo -e "\nTiles added."

i=0
for f in $filelist
do
  echo -ne "Downloading $((100*i/($width_in_tiles*$height_in_tiles)))%   \r" > /dev/stderr
  convert "$f" miff:-
  let i=$i+1
done | montage - -geometry +0+0 -tile "$width_in_tiles"x"$height_in_tiles" result.jpg
