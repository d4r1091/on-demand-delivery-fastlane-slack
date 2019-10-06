#!/bin/sh

# 2012 - Ben Clayton (benvium). Calvium Ltd
# 2017 - Dario Carlomagno (d4r1091). Tictrac Ltd
#
# This script installs a .mobileprovision file without using Xcode. Unlike Xcode, it'll
# work over SSH.
#
# Requires Mac OS X (I'm using 10.7 and Xcode 4.3.2)
#
# Usage installMobileProvisionFile.sh path/to/foobar.mobileprovision

if [ ! $# == 1 ]; then
echo "Usage: $0 (path/to/mobileprovision)"
exit
fi

mp=$1

uuid=`echo $(security cms -D -i ${mp}) | sed -n "/UUID/ s/.*<string>\(.*\)<\/string>.*/\1/p"`

echo "Found UUID $uuid"

output="$HOME/Library/MobileDevice/Provisioning Profiles/$uuid.mobileprovision"

echo "copying to $output..."
cp -f "${mp}" "$output"

echo "done"
