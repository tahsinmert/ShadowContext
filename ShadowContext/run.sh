#!/bin/bash

# Configuration
APP_NAME="ShadowContext"
BUNDLE_ID="com.vibe.ShadowContext"
TARGET_DIR="build"
APP_BUNDLE="${TARGET_DIR}/${APP_NAME}.app"

# Clean previous build
echo "🧹 Cleaning previous build..."
rm -rf "${TARGET_DIR}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Source files
# We find all .swift files in the current directory and subdirectories
SWIFT_FILES=$(find . -name "*.swift")

echo "🔨 Compiling ShadowContext..."
# Compile for Apple Silicon (arm64) and Intel (x86_64) if desired, but arm64 is default for this env.
# Adding -O for optimization and system framework links
swiftc -o "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" \
    -sdk $(xcrun --show-sdk-path --sdk macosx) \
    -target arm64-apple-macosx14.0 \
    -O \
    ${SWIFT_FILES}

# Check if compilation succeeded
if [ $? -ne 0 ]; then
    echo "❌ Compilation failed!"
    exit 1
fi

# Copy Info.plist
echo "📋 Adding Info.plist and Assets..."
cp Info.plist "${APP_BUNDLE}/Contents/Info.plist"

# Copy AppIcon
cp AppIcon.icns "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"

echo "🚀 Launching ${APP_NAME}..."
# Kill existing instance if running
killall "${APP_NAME}" 2>/dev/null

# Open the app
open "${APP_BUNDLE}"

echo "✅ Success! ShadowContext is running in the menu bar."
