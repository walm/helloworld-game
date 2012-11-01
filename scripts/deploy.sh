set -e

[ -z "$TESTFLIGHT_API" ] && echo "Need to set TESTFLIGHT_API" && exit 1;
[ -z "$TESTFLIGHT_TEAM" ] && echo "Need to set TESTFLIGHT_TEAM" && exit 1;

# Settings
BUILD_DIR="$(pwd)/build"
APP_NAME="Hello World"
DEVELOPER_NAME="iPhone Developer: Andreas Walm (8H"
PROVISONING_PROFILE="/Users/walan/Library/MobileDevice/Provisioning Profiles/77284694-9F29-4BDA-8F2A-18FD4B0DE5CD.mobileprovision"

[ -d $BUILD_DIR ] && rm -r $BUILD_DIR

# Pre requirements
bundle install
pod setup
pod install

# Build workspace
xcodebuild -workspace "${APP_NAME}.xcworkspace" -scheme "${APP_NAME}" -configuration release -sdk iphoneos build CONFIGURATION_BUILD_DIR="${BUILD_DIR}" CODE_SIGN_IDENTITY="${DEVELOPER_NAME}"

# Create IPA
xcrun -sdk iphoneos PackageApplication -v "${BUILD_DIR}/${APP_NAME}.app" -o "${BUILD_DIR}/${APP_NAME}.ipa" --sign "${DEVELOPER_NAME}" --embed "${PROVISONING_PROFILE}"

# Zip debug symbols
zip -r "${BUILD_DIR}/${APP_NAME}.app.dSYM.zip" "${BUILD_DIR}/${APP_NAME}.app.dSYM"

# Upload to TestFlight
curl http://testflightapp.com/api/builds.json \
    -F file=@"${BUILD_DIR}/${APP_NAME}.ipa" \
    -F dsym=@"${BUILD_DIR}/${APP_NAME}.app.dSYM.zip" \
    -F api_token="${TESTFLIGHT_API}"  \
    -F team_token="${TESTFLIGHT_TEAM}" \
    -F notes='Automatic upload from cli' \
    -F notify=False \
    -F distribution_lists='Testers'

