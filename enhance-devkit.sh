#!/bin/bash

# DevKit Flow Enhancement Script
# Enhances existing Next.js + Anchor project with DevKit Flow components

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
PROJECT_ROOT="$(pwd)"

# Logging functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

# Verify existing scaffold
verify_scaffold() {
    log "Verifying existing scaffold structure..."
    
    # Check for critical directories
    if [ ! -d "${PROJECT_ROOT}/anchor" ] || [ ! -d "${PROJECT_ROOT}/src" ]; then
        error "Expected scaffold structure not found. Please run from root of create-solana-dapp project"
    fi
    
    # Check for Next.js app structure
    if [ ! -d "${PROJECT_ROOT}/src/app" ] || [ ! -d "${PROJECT_ROOT}/src/components" ]; then
        error "Expected Next.js app structure not found"
    fi
    
    success "Scaffold verification complete"
}

# Enhance Anchor programs
enhance_programs() {
    log "Enhancing Anchor programs..."
    
    local PROGRAMS_DIR="${PROJECT_ROOT}/anchor/programs"
    
    # Define program IDs
    declare -A PROGRAM_IDS=(
        ["test-engine"]="EzCvHeuefRbpjA6gXAChdQiXp6qLVsAF3jWby3wCgTiz"
        ["deploy-guard"]="8FomnyS f1eniLttdgeTcEjPAqJoMzf5jYVvdUyH8MUND"
        ["chain-watch"]="tYvJgXVRNagbqjq6LuackN27qDxUDB2pRvN5GH6mZvM"
    )
    
    # Create new program directories alongside existing devkitflow
    for program in test-engine deploy-guard chain-watch; do
        mkdir -p "${PROGRAMS_DIR}/${program}/src"
        
        # Create Cargo.toml
        cat > "${PROGRAMS_DIR}/${program}/Cargo.toml" << EOL
[package]
name = "${program}"
version = "0.1.0"
description = "DevKit Flow ${program} component"
edition = "2021"

[lib]
crate-type = ["cdylib", "lib"]
name = "${program//-/_}"

[features]
no-entrypoint = []
no-idl = []
no-log-ix-name = []
cpi = ["no-entrypoint"]
default = []

[dependencies]
anchor-lang = { version = "0.30.1", features = ["init-if-needed"] }
EOL

        # Create lib.rs with proper program ID
        cat > "${PROGRAMS_DIR}/${program}/src/lib.rs" << EOL
use anchor_lang::prelude::*;

declare_id!("${PROGRAM_IDS[$program]}");

#[program]
pub mod ${program//-/_} {
    use super::*;
}
EOL

        # Create Xargo.toml
        cat > "${PROGRAMS_DIR}/${program}/Xargo.toml" << EOL
[target.bpfel-unknown-unknown.dependencies.std]
features = []
EOL
    done
    
    success "Anchor programs enhanced"
}

# Enhance test structure
enhance_tests() {
    log "Enhancing test structure..."
    
    local TESTS_DIR="${PROJECT_ROOT}/anchor/tests"
    
    # Create test directories for each program
    for program in test-engine deploy-guard chain-watch; do
        cat > "${TESTS_DIR}/${program}.spec.ts" << EOL
import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { PublicKey } from "@solana/web3.js";
import { expect } from "chai";

describe("${program}", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  it("Is initialized!", async () => {
    // Add your test here
  });
});
EOL
    done
    
    success "Test structure enhanced"
}

# Enhance frontend components
enhance_frontend() {
    log "Enhancing frontend structure..."
    
    # Add DevKit Flow specific pages
    mkdir -p "${PROJECT_ROOT}/src/app/test-engine"
    mkdir -p "${PROJECT_ROOT}/src/app/deploy-guard"
    mkdir -p "${PROJECT_ROOT}/src/app/chain-watch"
    
    # Add component directories
    for component in test-engine deploy-guard chain-watch; do
        local COMPONENT_DIR="${PROJECT_ROOT}/src/components/${component}"
        mkdir -p "${COMPONENT_DIR}"
        
        # Create data access file
        cat > "${COMPONENT_DIR}/${component}-data-access.tsx" << EOL
import { useConnection, useWallet } from '@solana/wallet-adapter-react';
import { PublicKey } from '@solana/web3.js';

export const use${component^}Program = () => {
  const { connection } = useConnection();
  const { publicKey } = useWallet();

  return {
    // Implementation will be added
  };
};
EOL

        # Create feature file
        cat > "${COMPONENT_DIR}/${component}-feature.tsx" << EOL
'use client';

import { ${component^}UI } from './${component}-ui';

export function ${component^}Feature() {
  return <${component^}UI />;
}
EOL

        # Create UI file
        cat > "${COMPONENT_DIR}/${component}-ui.tsx" << EOL
export function ${component^}UI() {
  return (
    <div>
      <h1>${component^}</h1>
      {/* Implementation will be added */}
    </div>
  );
}
EOL
    done
    
    # Add page files
    for component in test-engine deploy-guard chain-watch; do
        cat > "${PROJECT_ROOT}/src/app/${component}/page.tsx" << EOL
import { ${component^}Feature } from '@/components/${component}/${component}-feature';

export default function ${component^}Page() {
  return <${component^}Feature />;
}
EOL
    done

    # Create and populate config directory
    mkdir -p "${PROJECT_ROOT}/src/config"
    cat > "${PROJECT_ROOT}/src/config/program-ids.json" << EOL
{
    "testEngine": "EzCvHeuefRbpjA6gXAChdQiXp6qLVsAF3jWby3wCgTiz",
    "deployGuard": "8FomnyS f1eniLttdgeTcEjPAqJoMzf5jYVvdUyH8MUND",
    "chainWatch": "tYvJgXVRNagbqjq6LuackN27qDxUDB2pRvN5GH6mZvM"
}
EOL
    
    success "Frontend structure enhanced"
}

# Update configuration files
update_configurations() {
    log "Updating configuration files..."
    
    # Update anchor/Cargo.toml workspace if it exists
    if [ -f "${PROJECT_ROOT}/anchor/Cargo.toml" ]; then
        if ! grep -q "workspace" "${PROJECT_ROOT}/anchor/Cargo.toml"; then
            cat >> "${PROJECT_ROOT}/anchor/Cargo.toml" << EOL

[workspace]
members = [
    "programs/*"
]
EOL
        fi
    fi
    
    success "Configuration files updated"
}

# Main execution
main() {
    log "Starting DevKit Flow enhancement"
    
    verify_scaffold
    enhance_programs
    enhance_tests
    enhance_frontend
    update_configurations
    
    success "DevKit Flow enhancement completed successfully"
    log "Project structure enhanced at: ${PROJECT_ROOT}"
    
    echo -e "\nNext steps:"
    echo "1. Review the enhanced structure"
    echo "2. Build the Anchor programs with 'npm run anchor build'"
    echo "3. Run the development server with 'npm run dev'"
    echo "4. Update program IDs in the generated lib.rs files"
}

# Execute main function
main
