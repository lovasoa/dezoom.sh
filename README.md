# dezoom.sh
Download and assemble tiled images. Dezoomify for bash. Depends on imagemagick


## Install instructions

### Install dependencies

#### In linux (easy)
```bash
sudo apt install wget imagemagick
```
#### In MacOS
Install [brew](http://brew.sh/)
```bash
brew install imagemagick
brew install wget
```
#### In windows
Install [cygwin](https://cygwin.com/install.html), and inside it, install wget and [imagemagick](http://www.imagemagick.org/script/binary-releases.php).


### Download the script

```
wget -O dezoom.sh "https://raw.githubusercontent.com/lovasoa/dezoom.sh/master/dezoom.sh"
```

### Make it executable
```
chmod +x dezoom.sh
```

### Download your image
Use the script like that: `./dezoom.sh width height URL`

The first two parameters are the width and height (in number of tiles) of the image,
the third is the URL of the image, with the x position replaced by `%X` and the Y position by `%Y`

## Find the parameters to use

You have to know the width and height (in tiles) in your image.
One solution is to find it by trial and error.
Another is to open the zoomable image in your browser, open the network inspector of your browser,
zoom and scroll to the bottom right of the image, and see what is the last loaded tile.

For instance, if the last tile loaded is `http://example.com/tile.php?tilePositionX=188&tilePositionY=105`,
then you invoke the script like that:

```bash
./dezoom.sh 189 105 "http://example.com/tile.php?tilePositionX=%X&tilePositionY=%Y"
```
