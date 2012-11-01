set -e

bundle install
pod setup
pod install
xcodebuild -workspace Hello\ World.xcworkspace/ -scheme "Hello World" -configuration debug -sdk iphonesimulator clean build
