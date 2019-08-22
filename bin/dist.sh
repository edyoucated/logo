#!/bin/bash

SRC_DIR=src
DIST_DIR=dist

mkdir -p "$DIST_DIR"

if [ -z "$DIST_DIR" ]; then
  echo "Error: Empty DIST_DIR, exiting before attempting rm -rf"
  exit 99
else
  rm -rf "$DIST_DIR"/*
fi

function createLogoVersions() {
  LOGO_TYPE=$1

  echo "Generating dist files for '$LOGO_TYPE'"

  TARGET_DIR="$DIST_DIR/$LOGO_TYPE"

  mkdir -p "$TARGET_DIR"

  SRC_SVG="$SRC_DIR"/"$LOGO_TYPE".min.svg

  echo -n "  Generating SVG version..."
  TARGET_SVG="$TARGET_DIR"/"$LOGO_TYPE".svg
  cp "$SRC_SVG" "$TARGET_SVG"
  echo "OK"

  echo "  Generating PNG versions..."
  resize 64
  resize 196
  resize 256
  resize 368
  resize 512
  resize 1024
  resize 2048

  echo ""
}

function resize() {
  size=$1
  density=$((size * 4))
  echo -n "    $size"x...
  docker run --rm --volume "$PWD/$SRC_DIR/fonts/lato":"/usr/share/fonts/truetype/lato" --volume "$PWD/$SRC_SVG":"/app/input.svg" --volume "$PWD/$TARGET_DIR":"/output" --workdir "/app" jujhars13/docker-imagemagick sh -c "fc-cache -f; convert -background none -resize \"$size\"x -density \"$density\" -depth 8 input.svg /output/\"$LOGO_TYPE\"-\"$size\".png"
  echo "OK"
}

function optimizePng() {
  DIR=$1

  echo "Size before optimization"
  du -h --max-depth=0 "$DIR"

  echo -n "Optimizing..."
  CURRENT="$PWD"
  cd "$DIR"
  docker run --rm -v "$PWD":/source buffcode/docker-optipng -q -o7 **/*.png
  cd "$CURRENT"
  echo "OK"

  echo "Size after optimization"
  du -h --max-depth=0 "$DIR"
}

createLogoVersions "brand"
createLogoVersions "icon"
createLogoVersions "logo"
createLogoVersions "logo-and-brand"
createLogoVersions "logo-and-white-brand"
createLogoVersions "logo-and-white-brand-on-color"
createLogoVersions "logo-on-color-square"
createLogoVersions "logo-white"

optimizePng "$DIST_DIR"

bin/own.sh "$PWD/$DIST_DIR"
