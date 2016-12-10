#!/bin/bash

if [ $# -ne 3 ]
then
  echo "$0: invalid number of arguments

  Usage: $0 max_x max_y URL
    max_x: width of the full image in number of tiles
    max_y: height of the full image in number of tiles
    URL: the URL of individual tiles, with the x position replaced by %X and the y position replaced by %Y";
  exit 1;
fi

max_x=$1
max_y=$2
url_template=$3
width_in_tiles=$(( $max_x + 1 ))
height_in_tiles=$(( $max_y + 1 ))

imgid=$(echo -n "$url_template" | tr -c "[:alnum:]" "-")
export TMPDIR="$(dirname $(mktemp -u))/$imgid"
mkdir -p "$TMPDIR"
rm -f "$TMPDIR/failed_tiles.txt"

function download_file {
  outfile=$1
  url=$2
  retried=$3

  wget --timeout 20 -O "$outfile" "$url" 2>/dev/null
  tilesize=$(identify -format "%wx%h" "$outfile" 2> /dev/null)
  if [ $tilesize ]
  then
    echo $tilesize >> "$TMPDIR/tilesize.txt"
  else
    rm -f "$outfile"
    echo "Failed to download '$url'" >&2
    if [ ! $retried ]
    then
      sleep 5
      download_file $outfile $url true
    else
      echo "$url" >> "$TMPDIR/failed_tiles.txt"
    fi
  fi
}

filelist=''
for y in $(seq 0 $max_y)
do
  echo -ne "Downloading... $((100*$y/$height_in_tiles))%    \r" >&2
  for x in $(seq 0 $max_x)
  do
    url=$(echo $url_template | sed "s/%X/$x/" | sed "s/%Y/$y/")

    outfile="$TMPDIR"/tile"$x"_"$y".jpg
    if [ ! -e "$outfile" ]
    then
      download_file "$outfile" "$url" &
    fi
    filelist="$filelist $outfile"
  done
  wait
done

if [ ! -e "$TMPDIR/tilesize.txt" ]
then
  echo "Didn't manage to download any tile." >&2
  exit 1
fi

tilesize=$(head -n 1 "$TMPDIR/tilesize.txt")
i=0
for f in $filelist
do
  echo -ne "Assembling tiles: $((100*i/($width_in_tiles*$height_in_tiles)))%   \r" >&2
  convert "$f" miff:- 2>/dev/null
  if [ $? != 0 ]
  then
    # If the image could not be read, then generate a black tile instead
    convert -size "$tilesize" xc:black miff:-
  fi
  let i=$i+1
done | montage - -geometry +0+0 -tile "$width_in_tiles"x"$height_in_tiles" result.jpg

echo "Tiles successfully assembled in 'result.jpg'" >&2

if [ -e "$TMPDIR/failed_tiles.txt" ]
then
  echo "However, some tile downloads failed. You can try again later, as all successfully downloaded tiles were saved to '$TMPDIR'" >&2
else
  rm -rf "$TMPDIR"
fi
