#!/usr/bin/env bash

set -xe

system_arch="$(uname -m)"

sw_version="2.1.2"

appimagetool_version="e15a487"
appimagetool_filename="appimagetool-$system_arch.AppImage"
appimagetool_baseurl="https://github.com/orazioedoardo/appimagetool/releases/download/$appimagetool_version"

runtime_version="905f6cf"
runtime_filename="runtime-$system_arch"
runtime_baseurl="https://github.com/orazioedoardo/type2-runtime/releases/download/$runtime_version"

# Shared libraries as of Ubuntu 22.04
required_libs=(
	libSDL2_mixer-2.0.so.0
	libSDL2-2.0.so.0

	libbsd.so.0
	libdecor-0.so.0
	libFLAC.so.8
	libfluidsynth.so.3
	libinstpatch-1.0.so.2
	libmd.so.0
	libmodplug.so.1
	libogg.so.0
	libopus.so.0
	libsndfile.so.1
	libvorbis.so.0
	libvorbisenc.so.2
	libvorbisfile.so.3
	libXss.so.1
)

cmake -S . -B build
cmake --build build -j "$(nproc)"

mkdir -p SpaceCadetPinball.AppDir/usr/{bin,lib,share/{applications,metainfo,sounds}}

cp -a assets SpaceCadetPinball.AppDir/
cp -a bin/SpaceCadetPinball SpaceCadetPinball.AppDir/usr/bin/
cp -a Platform/Linux/{AppRun,SpaceCadetPinball.desktop} SpaceCadetPinball.AppDir/
cp -a Platform/Linux/SpaceCadetPinball.appdata.xml SpaceCadetPinball.AppDir/usr/share/metainfo/
cp -a Platform/Linux/SpaceCadetPinball.desktop SpaceCadetPinball.AppDir/usr/share/applications/
cp -a SpaceCadetPinball/Icon_192x192.png SpaceCadetPinball.AppDir/SpaceCadetPinball.png
cp -a /usr/share/sounds/sf2/TimGM6mb.sf2 SpaceCadetPinball.AppDir/usr/share/sounds/

# For some reason this library is not in /lib/$system_arch-linux-gnu/$lib
cp -a -L /usr/lib/libopusfile.so.0 SpaceCadetPinball.AppDir/usr/lib/

for lib in "${required_libs[@]}"; do
	cp -a -L "/lib/$system_arch-linux-gnu/$lib" SpaceCadetPinball.AppDir/usr/lib/
done

if [ ! -f "$appimagetool_filename" ]; then
	curl -sSf -L -O "$appimagetool_baseurl/$appimagetool_filename"
	chmod +x "$appimagetool_filename"
fi

if [ ! -f "$runtime_filename" ]; then
	curl -sSf -L -O "$runtime_baseurl/$runtime_filename"
	chmod +x "$runtime_filename"
fi

./"$appimagetool_filename" --no-appstream --runtime-file "runtime-$system_arch" SpaceCadetPinball.AppDir "SpaceCadetPinball-$sw_version-linux-$system_arch.AppImage"

rm -r SpaceCadetPinball.AppDir
