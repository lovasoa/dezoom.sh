#!/bin/bash

if [ $# -ne 3 ]
then
  echo "$0: invalid number of arguments

  Usage: $0 width height URL
    width: width of the full image in number of tiles
    height: height of the full image in number of tiles
    URL: the URL of individual tiles, with the x position replaced by %X and the y position replaced by %Y";
  exit 1;
fi

width_in_tiles=$1
height_in_tiles=$2
url_template=$3

export TMPDIR=$(mktemp -d)

function download_file {
  outfile=$1
  url=$2
  wget -O "$outfile" "$url" 2>/dev/null
  if [[ $(file "$outfile") != *"image"* ]]
  then
    rm -f "$outfile"
    echo "Failed to download '$url'"
  else
    identify -format "%wx%h\n" "$outfile" >> "$TMPDIR/tilesizes.txt"
  fi
}

filelist=""
for y in $(seq $height_in_tiles)
do
  echo -ne "Downloading... $((100*$y/$height_in_tiles))%    \r"
  for x in $(seq $width_in_tiles)
  do
    url=$(echo $url_template | sed "s/%X/$x/" | sed "s/%Y/$y/")

    outfile="$TMPDIR"/tile"$x"_"$y".jpg
    download_file "$outfile" "$url" &
    filelist="$filelist $outfile"
  done
  wait
done

echo -e "\nTiles added."

tilesize=$(head -n 1 "$TMPDIR/tilesizes.txt")
i=0
for f in $filelist
do
  echo -ne "Assembling tiles: $((100*i/($width_in_tiles*$height_in_tiles)))%   \r" > /dev/stderr
  if [ -e "$f" ]
  then
    convert "$f" miff:-
  else
    convert -size "$tilesize" xc:black miff:-
  fi
  let i=$i+1
done | montage - -geometry +0+0 -tile "$width_in_tiles"x"$height_in_tiles" result.jpg

echo "Tiles successfully assembled in 'result.jpg'"

rm -rf "$TMPDIR"
