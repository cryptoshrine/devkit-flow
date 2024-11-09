#!/bin/bash
# verify.sh

# Exit on error
set -e

# Print timestamp function
timestamp() {
  date +"[%Y-%m-%d %H:%M:%S]"
}

echo "$(timestamp) Starting verification of migrated DevKit Flow project"

# Verify program structure
echo "$(timestamp) Verifying program structure..."
# Check for required program files
[[ -f "new_structure/programs/test-engine/Cargo.toml" ]] && echo "[SUCCESS] Found programs/test-engine/Cargo.toml" || { echo "[ERROR] Missing programs/test-engine/Cargo.toml"; exit 1; }
[[ -f "new_structure/programs/test-engine/src/lib.rs" ]] && echo "[SUCCESS] Found programs/test-engine/src/lib.rs" || { echo "[ERROR] Missing programs/test-engine/src/lib.rs"; exit 1; }
[[ -f "new_structure/programs/test-engine/src/state/mod.rs" ]] && echo "[SUCCESS] Found programs/test-engine/src/state/mod.rs" || { echo "[ERROR] Missing programs/test-engine/src/state/mod.rs"; exit 1; }
[[ -f "new_structure/programs/test-engine/src/errors/mod.rs" ]] && echo "[SUCCESS] Found programs/test-engine/src/errors/mod.rs" || { echo "[ERROR] Missing programs/test-engine/src/errors/mod.rs"; exit 1; }

# Check for instructions directory
[[ -d "new_structure/programs/test-engine/src/instructions" ]] && echo "[SUCCESS] Found instructions directory" || { echo "[ERROR] Missing instructions directory"; exit 1; }
[[ $(ls -A "new_structure/programs/test-engine/src/instructions") ]] && echo "[SUCCESS] Instructions directory contains files" || { echo "[ERROR] Instructions directory is empty"; exit 1; }

echo "[SUCCESS] Program structure verification passed"

# Verify test structure
echo "$(timestamp) Verifying test structure..."
# Check for required test files - Updated to look for .spec.ts files
[[ -f "new_structure/tests/unit/test-engine/test-engine.spec.ts" ]] && echo "[SUCCESS] Found tests/unit/test-engine/test-engine.spec.ts" || { echo "[ERROR] Missing tests/unit/test-engine/test-engine.spec.ts"; exit 1; }
[[ -f "new_structure/tests/unit/deploy-guard/deploy-guard.spec.ts" ]] && echo "[SUCCESS] Found tests/unit/deploy-guard/deploy-guard.spec.ts" || { echo "[ERROR] Missing tests/unit/deploy-guard/deploy-guard.spec.ts"; exit 1; }
[[ -f "new_structure/tests/integration/integration-tests.spec.ts" ]] && echo "[SUCCESS] Found tests/integration/integration-tests.spec.ts with content" || { echo "[ERROR] Missing or empty integration tests"; exit 1; }
[[ -f "new_structure/tests/utils/test-helpers.ts" ]] && echo "[SUCCESS] Found tests/utils/test-helpers.ts with content" || { echo "[ERROR] Missing or empty test helpers"; exit 1; }

# Check test structure
test_files_exist=$?
if [ $test_files_exist -eq 0 ]; then
    echo "[SUCCESS] Test structure verification passed"
else
    echo "[ERROR] Test structure verification failed"
    exit 1
fi

# Verify configuration files
echo "$(timestamp) Verifying configuration files..."
# Check for tsconfig.json and package.json
[[ -f "new_structure/tsconfig.json" ]] && echo "[SUCCESS] Found tsconfig.json" || echo "[WARNING] tsconfig.json might be missing path mappings"
[[ -f "new_structure/package.json" ]] && echo "[SUCCESS] Found package.json" || { echo "[ERROR] Missing package.json"; exit 1; }

echo "[SUCCESS] Configuration files verification passed"

# Verify documentation structure
echo "$(timestamp) Verifying documentation structure..."
[[ -f "new_structure/docs/architecture/test-engine.md" ]] && echo "[SUCCESS] Found docs/architecture/test-engine.md with content" || { echo "[ERROR] Missing test-engine architecture documentation"; exit 1; }
[[ -f "new_structure/docs/testing/unit-testing.md" ]] && echo "[SUCCESS] Found docs/testing/unit-testing.md with content" || { echo "[ERROR] Missing unit testing documentation"; exit 1; }

echo "[SUCCESS] Documentation verification passed"

# Final verification status
if [ $? -eq 0 ]; then
    echo "[SUCCESS] All verifications passed"
else
    echo "[ERROR] Some verifications failed. Please check the logs above"
    exit 1
fi
