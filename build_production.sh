#!/bin/bash

echo "Building MPN-Info Flutter Application..."

# Build the Flutter application
echo "Building Flutter app..."
flutter build linux --release

# Create data and images directories in build output
echo "Setting up external data directories..."
BUILD_DIR="build/linux/x64/release/bundle"
mkdir -p "$BUILD_DIR/data"
mkdir -p "$BUILD_DIR/images"

# Copy data files
echo "Copying data files..."
cp -r assets/data/* "$BUILD_DIR/data/"

# Copy image files
echo "Copying image files..."
cp -r assets/images/* "$BUILD_DIR/images/"
cp -r assets/icons/* "$BUILD_DIR/images/"

# Create distribution directory
echo "Creating distribution directory..."
DIST_DIR="/opt/mpn-info"
sudo mkdir -p "$DIST_DIR"
sudo mkdir -p "$DIST_DIR/data"
sudo mkdir -p "$DIST_DIR/images"

# Copy executable and dependencies
echo "Copying application files..."
sudo cp "$BUILD_DIR"/* "$DIST_DIR/" 2>/dev/null || true
sudo cp -r "$BUILD_DIR/lib" "$DIST_DIR/" 2>/dev/null || true

# Copy data and images to distribution
echo "Copying data and images to distribution..."
sudo cp -r "$BUILD_DIR/data"/* "$DIST_DIR/data/"
sudo cp -r "$BUILD_DIR/images"/* "$DIST_DIR/images/"

# Set permissions
sudo chmod +x "$DIST_DIR"/*.so 2>/dev/null || true
sudo chmod +x "$DIST_DIR"/mpn_info_flutter 2>/dev/null || true

echo ""
echo "Build completed successfully!"
echo "Application location: $DIST_DIR"
echo ""
echo "Directory structure:"
echo "/opt/mpn-info/"
echo "├── mpn_info_flutter"
echo "├── lib/"
echo "├── data/"
echo "│   ├── db-struct"
echo "│   ├── db-value"
echo "│   ├── kantor.csv"
echo "│   ├── klu.csv"
echo "│   ├── map.csv"
echo "│   ├── jatuhtempo.csv"
echo "│   ├── maxlapor.csv"
echo "│   └── update-x.x/"
echo "└── images/"
echo "    ├── logo-medium.png"
echo "    └── ..."
echo ""