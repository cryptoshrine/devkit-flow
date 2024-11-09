#!/bin/bash
# fix_all_package_json.sh

# Fix root package.json
cat > "${PWD}/package.json" << 'EOF'
{
  "name": "devkit-flow",
  "version": "1.0.0",
  "private": true,
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

# Fix new_structure package.json
cat > "${PWD}/new_structure/package.json" << 'EOF'
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

# Clean up existing node_modules and lock files in both directories
rm -rf node_modules package-lock.json yarn.lock pnpm-lock.yaml
rm -rf new_structure/node_modules new_structure/package-lock.json new_structure/yarn.lock new_structure/pnpm-lock.yaml

# Install dependencies in both directories
npm install
cd new_structure && npm install

echo "Updated both package.json files and reinstalled dependencies"
