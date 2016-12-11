#!/bin/bash
# dezoom.sh, by Ophir LOJKINE

export xmin=0
export xmax="inf"
export dx=1
export ymin=0
export ymax="inf"
export dy=1
export outfile='result.jpg'
export retry_downloads=true
export url_template=''
export TMPDIR=''

function show_usage {
  echo "
Usage: $0 [-x min_x] [-X max_x] [-u delta_x] [-y min_y] [-Y max_y] [-v delta_y] [-o outfile] TEMPLATE_URL
  -x min_x, -y min_y: coordinates of the first tile (default: 0,0)
  -X max_x, -Y max_y: coordinates of the last tile (default: detect automatically)
  -u delta_x, -v delta_y: increment in x and y between consecutive tiles (default: 1,1)
  -o outfile: name of the result file to create (default: result.jpg)
  -f: Fast mode: don't retry downloads when they fail (default: false)
  TEMPLATE_URL: the URL of individual tiles, with the x position replaced by %X and the y position replaced by %Y" >&2
  exit 1;
}

function assert_valid_integers {
  for int in $@; do
    if [[ ! "$int" =~ ^-?[0-9]+$ ]]; then
      echo "Invalid number: $1" >&2
      show_usage
    fi
  done
}

function tile_file {
  echo "$TMPDIR"/tile"$1"_"$2".jpg
}

function download_tile {
  x=$1
  y=$2
  retried=$3
  url=$(echo $url_template | sed "s/%X/$x/" | sed "s/%Y/$y/")
  outfile=$(tile_file $x $y)

  if [[ ! -e "$outfile" ]]; then
    wget --timeout 20 -O "$outfile" "$url" 2>/dev/null
  fi

  tilesize=$(identify -format "%wx%h" "$outfile" 2> /dev/null)
  if [[ $tilesize ]]; then
    echo $tilesize >> "$TMPDIR/tilesize.txt"
    return 0
  else
    rm -f "$outfile"
    echo "Failed to download '$url'" >&2
    if [[ ( ! $retried )  && ( $retry_downloads = true ) ]]
    then
      sleep 5
      download_tile $x $y true
      return $?
    else
      echo "$url" >> "$TMPDIR/failed_tiles.txt"
      return 1
    fi
  fi
}

function download_x { download_tile "$1" "$ymin"; }
function download_y { download_tile "$xmin" "$1"; }

function all_xy {
  seq $ymin $dy $ymax | while read y; do
    seq $xmin $dx $xmax | while read x; do
      echo $x $y
    done
  done
}

function dichotomic_search {
  min=$1
  max=$2
  command=$3

  while [[ $min < $max ]]; do
    current=$(( (min + max + 1 ) / 2 ))
    if $command $current
      then min=$current
      else max=$((current - 1))
    fi
  done
  echo $min
}

while getopts ":x:X:y:Y:o:f" opt; do
  case "$opt" in
    X) xmax=$OPTARG;;
    x) xmin=$OPTARG;;
    Y) ymax=$OPTARG;;
    y) ymin=$OPTARG;;
    u) dx=$OPTARG;;
    v) dy=$OPTARG;;
    o) outfile=$OPTARG;;
    f) retry_downloads=false;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      show_usage
      ;;
    :)
      echo "Option -$OPTARG requires an argument" >&2
      show_usage
      ;;
  esac
done
shift $((OPTIND - 1)) 

# Avoid infinite loops: if xmax is smaller than xmin, then dx should be negative
if [[ $(( (xmax - xmin) / dx )) -lt 0 ]]; then
  dx=$((-dx))
fi
if [[ $(( (ymax - ymin) / dy )) -lt 0 ]]; then
  dy=$((-dy))
fi

url_template="$1"
if [[ ! "$url_template" ]]; then
  show_usage
fi

imgid=$(echo -n "$url_template" | tr -c "[:alnum:]" "-")
export TMPDIR="$(dirname $(mktemp -u))/$imgid"
mkdir -p "$TMPDIR"

if [[ "$xmax" = "inf" ]]; then
  echo "Guessing xmax..." >&2
  xmax=$(dichotomic_search "$xmin" $((dx*1000)) download_x)
fi
if [[ "$ymax" = "inf" ]]; then
  echo "Guessing ymax..." >&2
  ymax=$(dichotomic_search "$ymin" $((dy*1000)) download_y)
fi

assert_valid_integers $xmin $xmax $ymin $ymax

# Tile that failed to load during dichotomic search are normal
rm -f "$TMPDIR/failed_tiles.txt"

#Count the total number of tiles (xmax may be smaller than xmin)
width_in_tiles=$(( (xmax - xmin) / dx + 1))
height_in_tiles=$(( (ymax - ymin) / dy + 1))
total_tiles=$((width_in_tiles * height_in_tiles))

i=1
pids=''
all_xy | while read xy; do
  echo -ne "Downloading... $((100 * i / total_tiles))%    \r" >&2
  download_tile $xy &
  pids="$pids $!"
  # Do maximum 13 simultaneous connections
  if [[ ($((i % 13)) = 0) || $i = $total_tiles ]]; then
    wait $pids
    pids=''
  fi
  let i=i+1
done

if [ ! -e "$TMPDIR/tilesize.txt" ]
then
  echo "Didn't manage to download any tile." >&2
  exit 1
fi

tilesize=$(head -n 1 "$TMPDIR/tilesize.txt")
i=1
all_xy | while read xy; do
  echo -ne "Reading tiles: $((100 * i / total_tiles ))%   \r" >&2
  convert "$(tile_file $xy)" miff:- 2>/dev/null
  if [ $? != 0 ]
  then
    # If the image could not be read, then generate a black tile instead
    convert -size "$tilesize" xc:black miff:-
  fi
  if [[ $i = $total_tiles ]]; then
    echo "Assembling tiles... (this can be long)" >&2
  fi
  let i=i+1
done | montage - -geometry +0+0 -tile "$width_in_tiles"x"$height_in_tiles" "$outfile"

echo "Tiles successfully assembled in '$outfile'" >&2

if [ -e "$TMPDIR/failed_tiles.txt" ]
then
  echo "However, some tile downloads failed. You can try again later, as all successfully downloaded tiles were saved to '$TMPDIR'" >&2
else
  rm -rf "$TMPDIR"
fi
