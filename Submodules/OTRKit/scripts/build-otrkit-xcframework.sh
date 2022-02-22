#!/bin/bash

# User variables
# VARIABLE : valid options

set -e

cd "`dirname \"$0\"`"
TOPDIR=$(pwd)

# Combine build results of different archs into one
FINAL_BUILT_DIR="${TOPDIR}/../OTRKitDependencies/"
mkdir -p "${FINAL_BUILT_DIR}"
OTRKIT_XCFRAMEWORK="${FINAL_BUILT_DIR}/OTRKit.xcframework"

if [ -d "${OTRKIT_XCFRAMEWORK}" ]; then
  echo "Final OTRKit.xcframework found, skipping build..."
  exit 0
fi

BUILT_DIR="${TOPDIR}/built"
if [ ! -d "${BUILT_DIR}" ]; then
  mkdir -p "${BUILT_DIR}"
fi

ARCHIVES_DIR="${BUILT_DIR}/archives"
if [ ! -d "${ARCHIVES_DIR}" ]; then
  mkdir -p "${ARCHIVES_DIR}"
fi

XCFRAMEWORK_INPUTS=""

function archive {
  xcrun xcodebuild archive \
    -project ../OTRKit.xcodeproj \
    -scheme "${1}" \
    -destination "${2}" \
    -archivePath "${3}" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES
}

IOS_ARCHIVE_DIR="${ARCHIVES_DIR}/iOS"
IOS_SIMULATOR_ARCHIVE_DIR="${ARCHIVES_DIR}/iOS-Simulator"
IOS_CATALYST_ARCHIVE_DIR="${ARCHIVES_DIR}/iOS-Catalyst"
MACOS_ARCHIVE_DIR="${ARCHIVES_DIR}/macOS"

# Creates xc framework
function createXCFramework {
  FRAMEWORK_ARCHIVE_PATH_POSTFIX=".xcarchive/Products/Library/Frameworks"
  FRAMEWORK_SIMULATOR_DIR="${IOS_SIMULATOR_ARCHIVE_DIR}${FRAMEWORK_ARCHIVE_PATH_POSTFIX}"
  FRAMEWORK_DEVICE_DIR="${IOS_ARCHIVE_DIR}${FRAMEWORK_ARCHIVE_PATH_POSTFIX}"
  FRAMEWORK_CATALYST_DIR="${IOS_CATALYST_ARCHIVE_DIR}${FRAMEWORK_ARCHIVE_PATH_POSTFIX}"
  FRAMEWORK_MAC_DIR="${MACOS_ARCHIVE_DIR}${FRAMEWORK_ARCHIVE_PATH_POSTFIX}"
  xcodebuild -create-xcframework \
            -framework "${FRAMEWORK_SIMULATOR_DIR}/${1}.framework" \
            -framework "${FRAMEWORK_DEVICE_DIR}/${1}.framework" \
            -framework "${FRAMEWORK_CATALYST_DIR}/${1}.framework" \
            -framework "${FRAMEWORK_MAC_DIR}/${1}.framework" \
            -output "${OTRKIT_XCFRAMEWORK}"
}

archive "OTRKit (iOS)" "generic/platform=iOS" "${IOS_ARCHIVE_DIR}"
archive "OTRKit (iOS)" "generic/platform=iOS Simulator" "${IOS_SIMULATOR_ARCHIVE_DIR}"
archive "OTRKit (iOS)" "generic/platform=macOS" "${IOS_CATALYST_ARCHIVE_DIR}"
archive "OTRKit (macOS)" "generic/platform=macOS" "${MACOS_ARCHIVE_DIR}"

createXCFramework OTRKit

echo "Success! Finished building OTRKit.xcframework."