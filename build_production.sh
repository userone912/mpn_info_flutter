#!/bin/bash

echo "Building MPN-Info Flutter Application..."

# Build the Flutter application
echo "Building Flutter app..."
flutter build linux --release

# Create data directory in build output
echo "Setting up data directory..."
BUILD_DIR="build/linux/x64/release/bundle"
mkdir -p "$BUILD_DIR/data"

# Copy data files from project root data folder
echo "Copying data files..."
cp -r data/* "$BUILD_DIR/data/"

echo ""
echo "Build completed successfully!"
echo "Application location: $BUILD_DIR"
echo ""
echo "Directory structure:"
echo "$BUILD_DIR/"
echo "├── mpn_info_flutter"
echo "├── lib/"
echo "└── data/"
echo "    ├── db-struct"
echo "    ├── db-value"
echo "    ├── kantor.csv"
echo "    ├── klu.csv"
echo "    ├── map.csv"
echo "    ├── jatuhtempo.csv"
echo "    ├── maxlapor.csv"
echo "    └── update-x.x/"
echo ""
echo "Next steps:"
echo "1. Test the application: $BUILD_DIR/mpn_info_flutter"
echo "2. Configure database on first run (settings.ini will be created)"
echo "3. Update data files in $BUILD_DIR/data/ as needed"
echo "4. Distribute the entire $BUILD_DIR directory"
echo ""