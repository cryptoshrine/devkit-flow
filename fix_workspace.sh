#!/bin/bash

# Fix workspace script with proper permissions handling
set -e

# Get the directory where the script is running
SCRIPT_DIR="$(pwd)"
NEW_STRUCTURE_ROOT="${SCRIPT_DIR}/new_structure"

echo "Creating directories..."
# Create base directories with proper permissions
mkdir -p "${NEW_STRUCTURE_ROOT}"
chmod 755 "${NEW_STRUCTURE_ROOT}"

# Create Anchor.toml
echo "Creating Anchor.toml..."
cat > "${NEW_STRUCTURE_ROOT}/Anchor.toml" << 'EOF'
[features]
seeds = false
skip-lint = false

[programs.localnet]
test_engine = "DRtryNc2GJrhytBQK9STjphH5wyNopKuzne34kgdbLgx"

[registry]
url = "https://api.apr.dev"

[provider]
cluster = "Localnet"
wallet = "~/.config/solana/id.json"

[scripts]
test = "yarn run ts-mocha -p ./tsconfig.json tests/**/*.ts"

[workspace]
types = "target/types"
members = [
    "programs/test-engine"
]
EOF

# Create program directories
echo "Creating program directories..."
mkdir -p "${NEW_STRUCTURE_ROOT}/programs/test-engine/src/instructions"
chmod -R 755 "${NEW_STRUCTURE_ROOT}/programs"

# Create and populate instruction files
echo "Creating instruction files..."
for file in create_test run_test verify_results; do
    touch "${NEW_STRUCTURE_ROOT}/programs/test-engine/src/instructions/${file}.rs"
    chmod 644 "${NEW_STRUCTURE_ROOT}/programs/test-engine/src/instructions/${file}.rs"
done

echo "Workspace fixes completed"