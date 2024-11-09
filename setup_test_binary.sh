#!/bin/bash
# setup_test_binary.sh

# Exit on error
set -e

echo "Setting up program binary for testing..."

# Define directories
PROJECT_ROOT="${PWD}"
ANCHOR_DIR="${PROJECT_ROOT}/anchor"
TARGET_DIR="${ANCHOR_DIR}/target/deploy"
FIXTURE_DIR="${PROJECT_ROOT}/new_structure/tests/fixtures"

# Add the directory structure verification here
echo "Verifying directory structure..."

# Create all necessary test directories
mkdir -p "${PROJECT_ROOT}/new_structure/tests/fixtures"
mkdir -p "${PROJECT_ROOT}/new_structure/tests/unit/test-engine"
mkdir -p "${PROJECT_ROOT}/new_structure/tests/integration"
mkdir -p "${PROJECT_ROOT}/new_structure/tests/utils"

# Log the directory structure
echo "Directory structure:"
tree "${PROJECT_ROOT}/new_structure/tests"

# Continue with the rest of the script...
# Change to anchor directory first
if [ ! -f "${ANCHOR_DIR}/Cargo.toml" ]; then
    echo "Error: Could not find Anchor workspace at ${ANCHOR_DIR}"
    exit 1
fi

cd "${ANCHOR_DIR}"

# Define the rest of the paths relative to ANCHOR_DIR
TARGET_DIR="${ANCHOR_DIR}/target/deploy"
FIXTURE_DIR="${PROJECT_ROOT}/new_structure/tests/fixtures"

# Ensure the program is built
echo "Building program..."
anchor build

# Create fixtures directory if it doesn't exist
mkdir -p "${FIXTURE_DIR}"

# Copy the program binary
echo "Copying program binary to fixtures..."
cp "${TARGET_DIR}/test_engine.so" "${FIXTURE_DIR}/"

# Verify the copy
if [ -f "${FIXTURE_DIR}/test_engine.so" ]; then
    echo "Successfully copied program binary to ${FIXTURE_DIR}/test_engine.so"
else
    echo "Failed to copy program binary"
    exit 1
fi

echo "Test binary setup completed"
