#!/bin/bash
# update_package_json.sh

PROJECT_ROOT="${PWD}/new_structure"

# Update package.json
cat > "${PROJECT_ROOT}/package.json" << 'EOF'
{
  "name": "test-engine",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "test": "anchor test --skip-local-validator",
    "test:unit": "ts-mocha -p ./tsconfig.json tests/unit/**/*.ts",
    "test:integration": "ts-mocha -p ./tsconfig.json tests/integration/**/*.ts",
    "build": "anchor build"
  },
  "devDependencies": {
    "@coral-xyz/anchor": "^0.30.1",
    "@types/chai": "^4.3.5",
    "@types/mocha": "^10.0.1",
    "chai": "^4.3.7",
    "ts-mocha": "^10.0.0",
    "typescript": "^4.9.5",
    "solana-bankrun": "^0.4.0"
  },
  "dependencies": {
    "@solana/web3.js": "^1.78.0"
  }
}
EOF
