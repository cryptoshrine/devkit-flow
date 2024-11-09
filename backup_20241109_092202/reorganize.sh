#!/bin/bash

# DevKit Flow Project Reorganization Script
# This script reorganizes the project structure while maintaining a backup

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PROJECT_ROOT="$(pwd)"
BACKUP_DIR="${PROJECT_ROOT}/backup_$(date +%Y%m%d_%H%M%S)"
NEW_STRUCTURE_ROOT="${PROJECT_ROOT}/new_structure"

# Logging functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

# Create backup
create_backup() {
    log "Creating backup at ${BACKUP_DIR}"
    mkdir -p "${BACKUP_DIR}"
    
    # Copy files and directories individually, excluding the backup directory itself
    for item in "${PROJECT_ROOT}"/*; do
        if [[ "${item}" != *"backup_"* ]]; then
            cp -r "${item}" "${BACKUP_DIR}/"
        fi
    done
    
    success "Backup created successfully"
}

# Create new directory structure
create_directory_structure() {
    log "Creating new directory structure"
    
    # Programs structure
    mkdir -p "${NEW_STRUCTURE_ROOT}/programs/test-engine/src/"{state,instructions,errors,utils}
    mkdir -p "${NEW_STRUCTURE_ROOT}/programs/test-engine/tests/rust"
    
    # Test structure
    mkdir -p "${NEW_STRUCTURE_ROOT}/tests/"{fixtures/{test-cases,mock-data},unit/{test-engine,deploy-guard},integration,utils}
    
    # Documentation structure
    mkdir -p "${NEW_STRUCTURE_ROOT}/docs/"{architecture,api/test-engine,deployment,testing}
    
    success "Directory structure created"
}

# Migrate program files
migrate_program_files() {
    log "Migrating program files"
    
    local TEST_ENGINE_SRC="${PROJECT_ROOT}/programs/test-engine/src"
    local NEW_ENGINE_SRC="${NEW_STRUCTURE_ROOT}/programs/test-engine/src"
    
    # Create base directories
    mkdir -p "${NEW_ENGINE_SRC}/state"
    mkdir -p "${NEW_ENGINE_SRC}/instructions"
    mkdir -p "${NEW_ENGINE_SRC}/errors"
    
    # Copy files with error checking
    if [ -f "${TEST_ENGINE_SRC}/state.rs" ]; then
        cp "${TEST_ENGINE_SRC}/state.rs" "${NEW_ENGINE_SRC}/state/mod.rs"
    fi
    
    if [ -d "${TEST_ENGINE_SRC}/instructions" ]; then
        cp -r "${TEST_ENGINE_SRC}/instructions" "${NEW_ENGINE_SRC}/"
    fi
    
    if [ -f "${TEST_ENGINE_SRC}/errors.rs" ]; then
        cp "${TEST_ENGINE_SRC}/errors.rs" "${NEW_ENGINE_SRC}/errors/mod.rs"
    fi
    
    if [ -f "${TEST_ENGINE_SRC}/lib.rs" ]; then
        cp "${TEST_ENGINE_SRC}/lib.rs" "${NEW_ENGINE_SRC}/"
    fi
    
    # Copy Cargo.toml
    if [ -f "${PROJECT_ROOT}/programs/test-engine/Cargo.toml" ]; then
        cp "${PROJECT_ROOT}/programs/test-engine/Cargo.toml" "${NEW_STRUCTURE_ROOT}/programs/test-engine/"
    fi
    
    success "Program files migrated"
}

# Create documentation templates
create_documentation() {
    log "Creating documentation templates"
    
    # Create basic documentation files
    cat > "${NEW_STRUCTURE_ROOT}/docs/architecture/test-engine.md" << EOF
# Test Engine Architecture

## Overview
The Test Engine component of DevKit Flow handles automated testing and validation of Solana programs.

## Components
- TestCase Management
- Test Execution
- Results Verification

## Integration Points
- Deploy Guard Integration
- Chain Watch Integration
EOF
    
    cat > "${NEW_STRUCTURE_ROOT}/docs/testing/unit-testing.md" << EOF
# Unit Testing Guide

## Overview
This guide covers unit testing practices for the DevKit Flow project.

## Test Structure
- Test organization
- Naming conventions
- Best practices

## Running Tests
\`\`\`bash
yarn test:unit
\`\`\`
EOF
    
    success "Documentation templates created"
}

# Test migration function
test_migration() {
    log "Starting test migration"
    
    # Create a temporary test directory
    local TEST_DIR="/tmp/devkit-flow-test"
    mkdir -p "${TEST_DIR}"
    
    # Save original PROJECT_ROOT and NEW_STRUCTURE_ROOT
    local ORIG_PROJECT_ROOT="${PROJECT_ROOT}"
    local ORIG_NEW_STRUCTURE="${NEW_STRUCTURE_ROOT}"
    
    # Set test directories
    PROJECT_ROOT="${TEST_DIR}"
    NEW_STRUCTURE_ROOT="${TEST_DIR}/new_structure"
    
    log "Test directories:"
    log "Source: ${PROJECT_ROOT}"
    log "Destination: ${NEW_STRUCTURE_ROOT}"
    
    # Run only the migration function
    create_directory_structure
    migrate_program_files
    
    # Verify the migration
    log "Verifying migration results..."
    
    # Check key files
    local files_to_check=(
        "programs/test-engine/src/state/mod.rs"
        "programs/test-engine/src/errors/mod.rs"
        "programs/test-engine/src/lib.rs"
        "programs/test-engine/Cargo.toml"
    )
    
    local all_files_present=true
    for file in "${files_to_check[@]}"; do
        if [ -f "${NEW_STRUCTURE_ROOT}/${file}" ]; then
            success "Found ${file}"
        else
            error "Missing ${file}"
            all_files_present=false
        fi
    done
    
    # Clean up
    rm -rf "${TEST_DIR}"
    
    # Restore original paths
    PROJECT_ROOT="${ORIG_PROJECT_ROOT}"
    NEW_STRUCTURE_ROOT="${ORIG_NEW_STRUCTURE}"
    
    if [ "$all_files_present" = true ]; then
        success "Test migration completed successfully"
    else
        error "Test migration had issues"
    fi
}

# Main execution
main() {
    if [ "$1" = "test" ]; then
        test_migration
        return
    fi
    
    log "Starting DevKit Flow reorganization"
    create_backup
    create_directory_structure
    migrate_program_files
    create_documentation
    
    success "Reorganization completed successfully"
    log "New structure created at: ${NEW_STRUCTURE_ROOT}"
    log "Backup available at: ${BACKUP_DIR}"
}

# Execute main function with args
main "$@"
