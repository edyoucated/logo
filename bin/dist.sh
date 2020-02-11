#!/bin/bash

TYPES=(
    brand
    icon
    logo
    logo-and-brand
    logo-and-white-brand
    logo-and-white-brand-on-color
    logo-on-color-square
    logo-white
)

SIZES=(
    64
    196
    256
    368
    512
    1024
    2048
)

README_PREVIEW_SIZE=196


SRC_DIR=src
DIST_DIR=dist

function detectOperatingSystem() {
    unameOut="$(uname -s)"
    case "${unameOut}" in
        Linux*)     operatingSystem=Linux;;
        Darwin*)    operatingSystem=Mac;;
        *)          operatingSystem="UNKNOWN:${unameOut}"
    esac
    echo "Operating System: ${operatingSystem}"
}


function _du(){
  DIR=$1
  if [[ ${operatingSystem} == Mac ]]; then
    echo "Mac optimized"
    du -h -d=0 "$DIR"
  else
    du -h --max-depth=0 "$DIR"
  fi
}

mkdir -p "$DIST_DIR"

if [[ -z "$DIST_DIR" ]]; then
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

  for size in "${SIZES[@]}"
  do
    resize "$size"
  done

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

  _du "$DIR"

  echo -n "Optimizing..."
  CURRENT="$PWD"
  cd "$DIR"
  docker run --rm -v "$PWD":/source buffcode/docker-optipng -q -o7 **/*.png
  cd "$CURRENT"
  echo "OK"

  echo "Size after optimization"
  _du "$DIR"
}

function generateReadme() {
    target="$DIST_DIR/README.md"

    rm -f "$target"
    touch "$target"

    echo "# Images" >> "$target"
    echo "" >> "$target"

    for type in "${TYPES[@]}"
    do
        echo "## [$type]($type)" >> "$target"
        echo "" >> "$target"
        echo "![$type]($type/$type-$README_PREVIEW_SIZE.png?raw=true \"$type\")" >> "$target"
        echo "" >> "$target"
        echo "[svg]($type/$type.svg)" >> "$target"

        for size in "${SIZES[@]}"
        do
            echo "[png-$size]($type/$type-$size.png)" >> "$target"
        done
        echo "" >> "$target"
    done
}

detectOperatingSystem

for type in "${TYPES[@]}"
do
    createLogoVersions "$type"
done

optimizePng "$DIST_DIR"
generateReadme

bin/own.sh "$PWD/$DIST_DIR"
