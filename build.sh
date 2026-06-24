#!/bin/bash
set -e

echo "=== Building MarketWatch macOS Menu Bar Application ==="

# Get macOS SDK path dynamically
SDK_PATH=$(xcrun --show-sdk-path --sdk macosx)
echo "Using SDK: $SDK_PATH"

# Compile Swift files
swiftc -O \
    -sdk "$SDK_PATH" \
    main.swift AppDelegate.swift BreadthViews.swift Parser.swift FinvizMapView.swift \
    -o MarketWatch

echo "=== Compilation Succeeded! ==="
echo "You can now launch the app using: ./MarketWatch &"
