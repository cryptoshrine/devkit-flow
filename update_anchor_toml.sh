#!/bin/bash
# update_anchor_toml.sh

# Exit on error
set -e

PROJECT_ROOT="${PWD}"
ANCHOR_TOML="${PROJECT_ROOT}/anchor/Anchor.toml"

echo "Updating Anchor.toml..."

# Create or update Anchor.toml
cat > "${ANCHOR_TOML}" << 'EOF'
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

echo "Anchor.toml updated successfully"
