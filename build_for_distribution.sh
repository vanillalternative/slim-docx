#!/bin/bash

# SlimDocx Distribution Build Script
# This script builds a universal binary for both Apple Silicon and Intel Macs

echo "🏗️  Building SlimDocx for distribution..."
echo "📦 Creating universal binary (Apple Silicon + Intel)"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
xcodebuild clean -project SlimDocx.xcodeproj -scheme SlimDocx

# Build for Apple Silicon (ARM64)
echo "⚙️  Building ARM64 version..."
xcodebuild build -project SlimDocx.xcodeproj -scheme SlimDocx -configuration Release -derivedDataPath build_arm64 -arch arm64

# Build for Intel (x86_64)
echo "⚙️  Building x86_64 version..."
xcodebuild build -project SlimDocx.xcodeproj -scheme SlimDocx -configuration Release -derivedDataPath build_intel -arch x86_64

# Check if both builds succeeded
if [ $? -eq 0 ]; then
    echo "✅ Both builds successful!"
    
    # Create universal binary
    echo "🔄 Creating universal binary..."
    lipo -create \
        build_arm64/Build/Products/Release/SlimDocx.app/Contents/MacOS/SlimDocx \
        build_intel/Build/Products/Release/SlimDocx.app/Contents/MacOS/SlimDocx \
        -output SlimDocx_Universal
    
    # Use ARM64 app as base and replace binary with universal one
    APP_PATH="build_arm64/Build/Products/Release/SlimDocx.app"
    cp SlimDocx_Universal "$APP_PATH/Contents/MacOS/SlimDocx"
    
    # Remove quarantine attributes and re-sign the app
    echo "🔐 Removing quarantine attributes..."
    xattr -dr com.apple.quarantine "$APP_PATH" 2>/dev/null || true
    
    # Re-sign the app after modifying the binary
    echo "🔐 Re-signing universal app..."
    codesign --force --deep --sign - "$APP_PATH"
    
    if [ -d "$APP_PATH" ]; then
        echo "📱 Universal app created at: $APP_PATH"
        
        # Check architectures
        echo "🔍 Checking supported architectures..."
        lipo -info "$APP_PATH/Contents/MacOS/SlimDocx"
        
        # Verify code signature
        echo "🔐 Verifying code signature..."
        codesign --verify --verbose "$APP_PATH"
        
        # Create distribution folder
        DIST_BASE="dist"
        DIST_DIR="$DIST_BASE/SlimDocx_Distribution"
        echo "📦 Creating distribution package..."
        
        rm -rf "$DIST_BASE"
        mkdir -p "$DIST_DIR"
        
        # Copy app and remove quarantine from final package
        cp -R "$APP_PATH" "$DIST_DIR/"
        echo "🔐 Removing quarantine from distribution package..."
        xattr -dr com.apple.quarantine "$DIST_DIR/SlimDocx.app" 2>/dev/null || true
        
        # Copy README
        cp README.md "$DIST_DIR/"
        
        # Create simple instructions
        cat > "$DIST_DIR/Installation_Instructions.txt" << EOF
# SlimDocx Installation Instructions

## Quick Start:
1. Copy SlimDocx.app to your Applications folder
2. Double-click to launch
3. Drag DOCX files onto the app window
4. Choose where to save the compressed file
5. Done!

## First Launch Security Steps:
1. macOS will show "SlimDocx is damaged and can't be opened"
2. DON'T click "Move to Trash" - this is normal for unsigned apps
3. Instead: RIGHT-CLICK on SlimDocx.app → "Open"
4. Click "Open" in the security dialog that appears
5. App will now launch normally

## Alternative Method:
- Go to System Preferences → Security & Privacy → General
- Click "Open Anyway" next to SlimDocx message
- Then double-click the app to launch

## Troubleshooting:
- If app shows "damaged" error: Open Terminal and run:
  xattr -dr com.apple.quarantine /Applications/SlimDocx.app
  (Replace path if you put it elsewhere)
- Try running: sudo spctl --master-disable
  Then after opening app once: sudo spctl --master-enable
- If compression fails: Check file permissions
- For support: See README.md

## System Requirements:
- macOS 11.0 (Big Sur) or later
- Works on both Intel and Apple Silicon Macs

Enjoy smaller DOCX files! 📄✨
EOF
        
        # Create ZIP package
        echo "🗜️  Creating ZIP package..."
        cd "$DIST_BASE"
        zip -r "../SlimDocx_Universal_v1.0.zip" "SlimDocx_Distribution"
        cd ..
        
        # Move ZIP to dist folder and cleanup temporary files
        echo "🧹 Organizing files..."
        mv "SlimDocx_Universal_v1.0.zip" "$DIST_BASE/"
        rm -rf build_arm64 build_intel SlimDocx_Universal
        
        echo ""
        echo "🎉 Distribution package ready!"
        echo "📁 Package location: $(pwd)/$DIST_BASE/SlimDocx_Universal_v1.0.zip"
        echo "📊 Package size: $(du -h $DIST_BASE/SlimDocx_Universal_v1.0.zip | cut -f1)"
        echo ""
        echo "📨 Send '$DIST_BASE/SlimDocx_Universal_v1.0.zip' to your friend!"
        echo ""
        echo "🔍 Package contents:"
        unzip -l "$DIST_BASE/SlimDocx_Universal_v1.0.zip"
        
    else
        echo "❌ App not found at expected location"
        echo "🔍 Checking build directory..."
        find build -name "*.app" -type d
    fi
else
    echo "❌ Build failed!"
    exit 1
fi