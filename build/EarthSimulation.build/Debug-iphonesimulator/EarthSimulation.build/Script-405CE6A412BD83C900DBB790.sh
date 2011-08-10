#!/bin/sh
xcrun -sdk iphoneos texturetool -e PVRTC --bits-per-pixel-4 -o "$SRCROOT/Textures/Texture.pvr" -f PVR "$SRCROOT/Textures/Texture.png"
