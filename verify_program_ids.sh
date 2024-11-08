#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

echo -e "${BOLD}DevKit Flow Program ID Verification Script${NC}\n"

# Function to extract program ID from Rust file
get_rust_program_id() {
    local file=$1
    if [[ -f "$file" ]]; then
        grep "declare_id!" "$file" | grep -o '".*"' | tr -d '"'
    else
        echo "File not found"
    fi
}

# Function to extract program ID from TypeScript file
get_typescript_program_id() {
    local file=$1
    if [[ -f "$file" ]]; then
        grep "PROGRAM_ID.*=.*new.*PublicKey" "$file" | grep -o '".*"' | tr -d '"'
    else
        echo "File not found"
    fi
}

# Function to get program ID from keypair
get_keypair_id() {
    local keypair_file=$1
    if [[ -f "$keypair_file" ]]; then
        solana address -k "$keypair_file"
    else
        echo "Keypair not found"
    fi
}

# Function to check program ID in Anchor.toml
get_anchor_program_id() {
    local program_name=$1
    if [[ -f "Anchor.toml" ]]; then
        grep "$program_name = \".*\"" Anchor.toml | grep -o '".*"' | tr -d '"'
    else
        echo "Anchor.toml not found"
    fi
}

# Function to compare IDs and print results
compare_ids() {
    local program_name=$1
    local rust_id=$2
    local ts_id=$3
    local keypair_id=$4
    local anchor_id=$5

    echo -e "${BOLD}${program_name} Program IDs:${NC}"
    echo -e "Rust (lib.rs):     ${YELLOW}$rust_id${NC}"
    echo -e "TypeScript (test): ${YELLOW}$ts_id${NC}"
    echo -e "Keypair:           ${YELLOW}$keypair_id${NC}"
    echo -e "Anchor.toml:       ${YELLOW}$anchor_id${NC}"

    if [[ "$rust_id" == "$ts_id" && "$ts_id" == "$keypair_id" && "$keypair_id" == "$anchor_id" ]]; then
        echo -e "${GREEN}✓ All IDs match!${NC}"
    else
        echo -e "${RED}✗ ID mismatch detected!${NC}"
    fi
    echo "----------------------------------------"
}

# Function to verify deployed program
verify_deployed_program() {
    local program_id=$1
    local program_name=$2
    
    echo -e "\n${BOLD}Verifying deployment for $program_name${NC}"
    if solana program show "$program_id" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Program is deployed${NC}"
        solana program show "$program_id" | grep "Program Id\|Owner\|Last Deployed"
    else
        echo -e "${RED}✗ Program not found on chain${NC}"
    fi
}

# Main verification process
echo "Starting verification process..."
echo "----------------------------------------"

# Array of programs to check
declare -A programs=(
    ["test_engine"]="Test Engine"
    ["chain_watch"]="Chain Watch"
    ["deploy_guard"]="Deploy Guard"
    ["devkitflow"]="DevKit Flow"
)

# Check each program
for program in "${!programs[@]}"; do
    display_name="${programs[$program]}"
    
    # Get IDs from different sources
    rust_id=$(get_rust_program_id "programs/${program}/src/lib.rs")
    ts_id=$(get_typescript_program_id "tests/${program}.ts")
    keypair_id=$(get_keypair_id "target/deploy/${program}-keypair.json")
    anchor_id=$(get_anchor_program_id "$program")

    # Compare and display results
    compare_ids "$display_name" "$rust_id" "$ts_id" "$keypair_id" "$anchor_id"
    
    # Verify deployment if IDs match
    if [[ "$rust_id" == "$ts_id" && "$ts_id" == "$keypair_id" && "$keypair_id" == "$anchor_id" ]]; then
        verify_deployed_program "$rust_id" "$display_name"
    fi
done

# Additional cluster information
echo -e "\n${BOLD}Current Cluster Information:${NC}"
CLUSTER_URL=$(solana config get | grep "RPC URL" | cut -d : -f 2- | xargs)
echo "RPC URL: $CLUSTER_URL"
CLUSTER_TYPE="localnet"
if [[ $CLUSTER_URL == *"devnet"* ]]; then
    CLUSTER_TYPE="devnet"
elif [[ $CLUSTER_URL == *"mainnet"* ]]; then
    CLUSTER_TYPE="mainnet-beta"
fi
echo "Cluster Type: $CLUSTER_TYPE"

# Print help information
echo -e "\n${BOLD}Helpful Commands:${NC}"
echo "• Update program ID in Rust: sed -i 's/old_id/new_id/' programs/program_name/src/lib.rs"
echo "• Update program ID in TypeScript: sed -i 's/old_id/new_id/' tests/program_name.ts"
echo "• Update program ID in Anchor.toml: sed -i 's/old_id/new_id/' Anchor.toml"
echo "• Rebuild programs: anchor build"
echo "• Deploy programs: anchor deploy"
