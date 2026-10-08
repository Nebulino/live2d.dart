#!/bin/sh
if command -v fvm >/dev/null 2>&1; then
  FLUTTER_CMD="fvm flutter"
else
  FLUTTER_CMD="flutter"
fi

echo "Getting dependencies."
$FLUTTER_CMD pub get
echo "Running static analysis."
$FLUTTER_CMD analyze
echo "Running tests."
$FLUTTER_CMD test
echo "Finished building."
