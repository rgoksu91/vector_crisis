#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
MAGICK="/opt/homebrew/bin/magick"
FONT_BOLD="/System/Library/Fonts/Supplemental/Arial Bold.ttf"
FONT_REGULAR="/System/Library/Fonts/Supplemental/Arial.ttf"
BACKGROUND="$ROOT/brand/store_background_v1.png"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if [[ ! -x "$MAGICK" ]]; then
  echo "ImageMagick was not found at $MAGICK" >&2
  exit 1
fi

iphone_headline_en=(
  $'THINK AHEAD.\nCLEAR THE CHAOS.'
  $'300 PUZZLES.\nONE RISING CHALLENGE.'
  $'MASTER\nEVERY ARROW.'
  $'EVERY LEVEL\nGETS TOUGHER.'
  $'FROM SIMPLE\nTO MASTERY.'
  $'STUCK?\nTHINK SMARTER.'
)
iphone_subtitle_en=(
  'Read the board. Solve the order.'
  'A handcrafted journey that keeps evolving.'
  'Rotate. Thaw. Blast. Build walls.'
  'New dependencies. Fewer easy choices.'
  'Every level asks more of you.'
  'Limited hints reveal the next move.'
)
iphone_headline_tr=(
  $'İLERİYİ DÜŞÜN.\nKAOSU TEMİZLE.'
  $'300 BULMACA.\nGİDEREK ARTAN ZORLUK.'
  $'HER OKTA\nUSTALAŞ.'
  $'HER BÖLÜM\nDAHA ZOR.'
  $'BASİTTEN\nUSTALIĞA.'
  $'TAKILDIN MI?\nDAHA İYİ DÜŞÜN.'
)
iphone_subtitle_tr=(
  'Tahtayı oku. Doğru sırayı çöz.'
  'Sürekli gelişen, özenle tasarlanmış bir yolculuk.'
  'Döndür. Çöz. Patlat. Duvar kur.'
  'Yeni bağımlılıklar. Daha az kolay seçim.'
  'Her bölüm senden daha fazlasını ister.'
  'Sınırlı ipuçları sonraki hamleyi gösterir.'
)

ipad_headline_en=(
  $'THINK AHEAD.\nCLEAR THE CHAOS.'
  $'300 PUZZLES.\nONE RISING CHALLENGE.'
  $'MASTER EVERY ARROW.'
)
ipad_subtitle_en=(
  'Read the board. Solve the order.'
  'A handcrafted journey that keeps evolving.'
  'Rotate. Thaw. Blast. Build walls.'
)
ipad_headline_tr=(
  $'İLERİYİ DÜŞÜN.\nKAOSU TEMİZLE.'
  $'300 BULMACA.\nGİDEREK ARTAN ZORLUK.'
  $'HER OKTA USTALAŞ.'
)
ipad_subtitle_tr=(
  'Tahtayı oku. Doğru sırayı çöz.'
  'Sürekli gelişen, özenle tasarlanmış bir yolculuk.'
  'Döndür. Çöz. Patlat. Duvar kur.'
)

accent_colors=("#55E8FF" "#9E7BFF" "#FFC94A" "#63F4C3" "#7D9CFF" "#FFD05A")

array_value() {
  local array_name="$1"
  local array_index="$2"
  eval "printf '%s' \"\${${array_name}[${array_index}]}\""
}

render_iphone() {
  local locale="$1"
  local input_dir="$ROOT/raw/$locale"
  local output_dir="$ROOT/screenshots/iphone/$locale"
  mkdir -p "$output_dir"

  for index in {0..5}; do
    local n=$((index + 1))
    local source
    source="$(find "$input_dir" -maxdepth 1 -type f -name "0${n}_*.png" -print -quit)"
    local phone="$TMP_DIR/iphone_${locale}_${n}.png"
    local mask="$TMP_DIR/iphone_mask.png"
    local canvas="$TMP_DIR/iphone_canvas_${locale}_${n}.png"
    local headline subtitle
    headline="$(array_value "iphone_headline_${locale}" "$index")"
    subtitle="$(array_value "iphone_subtitle_${locale}" "$index")"

    "$MAGICK" "$source" -alpha off -resize '960x2086!' "$phone"
    "$MAGICK" -size 960x2086 xc:none -fill white \
      -draw 'roundrectangle 0,0 959,2085 60,60' "$mask"
    "$MAGICK" "$phone" "$mask" -alpha off -compose CopyOpacity -composite "$phone"

    "$MAGICK" "$BACKGROUND" -resize '1320x2868^' -gravity center -extent 1320x2868 \
      -fill '#06102ACC' -colorize 28% \
      -fill '#00000099' -draw 'roundrectangle 155,675 1165,2820 82,82' \
      "$canvas"

    "$MAGICK" "$canvas" \
      \( -background none -font "$FONT_BOLD" -fill white -gravity center \
         -pointsize 80 -interline-spacing -4 -size 1120x245 "caption:$headline" \) \
      -gravity north -geometry +0+115 -composite \
      \( -background none -font "$FONT_REGULAR" -fill "${accent_colors[$index]}" \
         -gravity center -pointsize 35 -size 1080x110 "caption:$subtitle" \) \
      -gravity north -geometry +0+430 -composite \
      "$phone" -gravity northwest -geometry +180+690 -composite \
      -fill none -stroke "${accent_colors[$index]}AA" -strokewidth 4 \
      -draw 'roundrectangle 178,688 1142,2778 62,62' \
      -alpha off -colorspace sRGB "PNG24:$output_dir/0${n}.png"
  done
}

render_ipad() {
  local locale="$1"
  local input_dir="$ROOT/raw_ipad/$locale"
  local output_dir="$ROOT/screenshots/ipad/$locale"
  mkdir -p "$output_dir"

  for index in {0..2}; do
    local n=$((index + 1))
    local source
    source="$(find "$input_dir" -maxdepth 1 -type f -name "0${n}_*.png" -print -quit)"
    local screen="$TMP_DIR/ipad_${locale}_${n}.png"
    local mask="$TMP_DIR/ipad_mask.png"
    local canvas="$TMP_DIR/ipad_canvas_${locale}_${n}.png"
    local headline subtitle
    headline="$(array_value "ipad_headline_${locale}" "$index")"
    subtitle="$(array_value "ipad_subtitle_${locale}" "$index")"

    "$MAGICK" "$source" -alpha off -resize '1500x2000!' "$screen"
    "$MAGICK" -size 1500x2000 xc:none -fill white \
      -draw 'roundrectangle 0,0 1499,1999 58,58' "$mask"
    "$MAGICK" "$screen" "$mask" -alpha off -compose CopyOpacity -composite "$screen"

    "$MAGICK" "$BACKGROUND" -resize '2064x2752^' -gravity center -extent 2064x2752 \
      -fill '#06102ACC' -colorize 28% \
      -fill '#00000099' -draw 'roundrectangle 242,672 1822,2732 82,82' \
      "$canvas"

    "$MAGICK" "$canvas" \
      \( -background none -font "$FONT_BOLD" -fill white -gravity center \
         -pointsize 108 -interline-spacing -8 -size 1780x300 "caption:$headline" \) \
      -gravity north -geometry +0+80 -composite \
      \( -background none -font "$FONT_REGULAR" -fill "${accent_colors[$index]}" \
         -gravity center -pointsize 48 -size 1700x120 "caption:$subtitle" \) \
      -gravity north -geometry +0+420 -composite \
      "$screen" -gravity northwest -geometry +282+700 -composite \
      -fill none -stroke "${accent_colors[$index]}AA" -strokewidth 5 \
      -draw 'roundrectangle 279,697 1785,2703 62,62' \
      -alpha off -colorspace sRGB "PNG24:$output_dir/0${n}.png"
  done
}

render_iphone en
render_iphone tr
render_ipad en
render_ipad tr

echo "App Store screenshots rendered under $ROOT/screenshots"
