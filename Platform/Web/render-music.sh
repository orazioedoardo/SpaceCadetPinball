#!/bin/sh
# Renders the game's MIDI music to Ogg Vorbis for the web build, which has no MIDI synth.
# The game loads <track>.OGG in place of <track>.MID when it exists (see midi::load_track).
#
# Needs fluidsynth, ffmpeg and oggenc (Homebrew: fluid-synth ffmpeg vorbis-tools) and a
# General MIDI SoundFont. The committed files were rendered with TimGM6mb, the SoundFont the
# Linux AppImage uses (Debian package timgm6mb-soundfont, /usr/share/sounds/sf2/TimGM6mb.sf2),
# with fluidsynth's default reverb and chorus.
#
# Usage: Platform/Web/render-music.sh [path/to/soundfont.sf2]
# Without an argument, TimGM6mb is downloaded from Debian (checked against a SHA-256) into a temp dir.
set -eu

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ASSETS="$ROOT/assets"
OUT="$ROOT/Platform/Web/music"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

TIMGM_DEB_URL="https://deb.debian.org/debian/pool/main/t/timgm6mb-soundfont/timgm6mb-soundfont_1.3-5_all.deb"
TIMGM_SHA256="c5378b62028c920cb11e4803327983fee2f2cdff5dc89c708e39da417e51c854"

if [ $# -ge 1 ]; then
	SOUNDFONT="$1"
else
	echo "Downloading TimGM6mb..."
	mkdir "$TMP/deb"
	curl -fsSL -o "$TMP/deb/timgm6mb.deb" "$TIMGM_DEB_URL"
	(cd "$TMP/deb" && ar x timgm6mb.deb && tar -xf data.tar.* ./usr/share/sounds/sf2/TimGM6mb.sf2)
	SOUNDFONT="$TMP/deb/usr/share/sounds/sf2/TimGM6mb.sf2"
	echo "$TIMGM_SHA256  $SOUNDFONT" | shasum -a 256 -c - >/dev/null
fi

render() {
	src="$ASSETS/$1.MID"
	dst="$OUT/$1.OGG"
	mkdir -p "$(dirname "$dst")"
	fluidsynth -ni -q -g 0.5 -r 44100 -F "$TMP/raw.wav" "$SOUNDFONT" "$src"
	# Drop the trailing silence so the track loops without a pause
	ffmpeg -loglevel error -y -i "$TMP/raw.wav" \
		-af "areverse,silenceremove=start_periods=1:start_threshold=-60dB,areverse" "$TMP/trimmed.wav"
	oggenc -Q -q 4 -o "$dst" "$TMP/trimmed.wav"
	echo "$dst"
}

# 3D Pinball (PINBALL.DAT): one track. PINBALL2.MID is a bitmap font, not music.
render PINBALL
# Full Tilt (CADET.DAT): three tracks in the SOUND folder
render SOUND/TABA1
render SOUND/TABA2
render SOUND/TABA3
