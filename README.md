# dezoom.sh
Download and assemble tiled images. Dezoomify for bash. Depends on imagemagick


## Install instructions

### Install dependencies

#### In linux (easy)
```bash
sudo apt install wget imagemagick
```
#### In MacOS
First install [brew](http://brew.sh/), then you can install the dependencies:

```bash
brew install imagemagick
brew install wget
```
#### In windows
Install [cygwin](https://cygwin.com/install.html), and inside it, install wget and [imagemagick](http://www.imagemagick.org/script/binary-releases.php).


### Download the script
You can use wget to download the script itself from the command-line:

```
wget -O dezoom.sh "https://raw.githubusercontent.com/lovasoa/dezoom.sh/master/dezoom.sh"
```

Or you can download it manually from your browser https://raw.githubusercontent.com/lovasoa/dezoom.sh/master/dezoom.sh.

### Make it executable
```
chmod +x dezoom.sh
```

### Download your image
Use the script like that: `./dezoom.sh template_url`

Where template_url is the URL of the image,
with the x position replaced by `%X` and the Y position by `%Y`

## Advanced usage

The script accepts additional parameters:
 * `-x` : the first value to use for `%X` (default: 0)
 * `-y` : the first value to use for `%Y` (default: 0)
 * `-X` : the last value to use for `%X` (default: detect automatically)
 * `-Y` : the last value to use for `%Y` (default: detect automatically)

If `-X` (respectively `-Y`) is not set, then its value will be detected automatically:
The script will perform a binary search to find the last value of `%X`
(respectively `%Y`) that returns a valid image.

### Find the parameters to use

You have to know the width and height (in tiles) in your image.

One solution is to find it by trial and error.

Another is to open the zoomable image in your browser,
open the network inspector of your browser,
zoom and scroll to the bottom right of the image,
and see what are the first and the last loaded tile.

For instance, if the first and last tiles loaded are:
 * first: `http://example.com/tile.php?tilePositionX=0&tilePositionY=0`,
 * last: `http://example.com/tile.php?tilePositionX=188&tilePositionY=105`,

then you invoke the script like that:

```bash
./dezoom.sh -x 0 -X 188 -y 0 -Y 105 "http://example.com/tile.php?tilePositionX=%X&tilePositionY=%Y"
```
