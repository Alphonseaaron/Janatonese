#!/bin/bash

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "Flutter is not installed. Please install Flutter to run this application."
    exit 1
fi

# Navigate to the Flutter project directory
cd janatonese

# Get Flutter dependencies
echo "Getting Flutter dependencies..."
flutter pub get

# Run the Flutter app
echo "Starting Flutter app..."
flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0