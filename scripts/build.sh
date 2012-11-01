set -e

xcodebuild -workspace Hello\ World.xcworkspace/ -scheme "Hello World" -configuration debug -sdk iphonesimulator clean build
