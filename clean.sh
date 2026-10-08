#!/bin/sh
if command -v fvm >/dev/null 2>&1; then
  FLUTTER_CMD="fvm flutter"
else
  FLUTTER_CMD="flutter"
fi

echo "Cleaning Flutter project build artifacts."
$FLUTTER_CMD clean
echo "Finished cleaning."
