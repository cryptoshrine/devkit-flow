#!/bin/bash
# update_all.sh

# Exit on error
set -e

echo "Starting updates..."

# Make scripts executable
chmod +x update_test_file.sh
chmod +x update_anchor_toml.sh

# Run updates
./update_test_file.sh
./update_anchor_toml.sh

echo "All updates completed successfully"
