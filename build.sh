#!/bin/bash
set -euo pipefail

echo "🔐 BTC Split Key - Security-First Build Script"
echo "=============================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Rust is installed
if ! command -v cargo &> /dev/null; then
    echo -e "${RED}❌ Rust/Cargo not found. Please install Rust first:${NC}"
    echo "   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    exit 1
fi

echo -e "${BLUE}🔍 Running security checks...${NC}"

# Update Rust toolchain
echo -e "${YELLOW}📦 Updating Rust toolchain...${NC}"
rustup update

# Run formatter
echo -e "${YELLOW}🎨 Formatting code...${NC}"
cargo fmt

# Run linter with security warnings
echo -e "${YELLOW}🔍 Running security lints...${NC}"
cargo clippy -- -D warnings -W clippy::panic -W clippy::unwrap_used

# Run tests
echo -e "${YELLOW}🧪 Running tests...${NC}"
cargo test

# Security audit (if cargo-audit is available)
if command -v cargo-audit &> /dev/null; then
    echo -e "${YELLOW}🔒 Running security audit...${NC}"
    cargo audit
else
    echo -e "${YELLOW}⚠️  cargo-audit not installed. Install with: cargo install cargo-audit${NC}"
fi

# Build release version with maximum security
echo -e "${YELLOW}🏗️  Building secure release version...${NC}"
RUSTFLAGS="-C target-cpu=native -C link-dead-code" cargo build --release

# Verify binary exists
if [[ -f "./target/release/bitcoin-keyforge" ]]; then
    echo ""
    echo -e "${GREEN}✅ Build successful!${NC}"
    echo -e "${GREEN}📁 Binary location: ./target/release/bitcoin-keyforge${NC}"

    # Show binary info
    ls -la ./target/release/bitcoin-keyforge

    # Test basic functionality
    echo ""
    echo -e "${BLUE}🧪 Testing basic functionality...${NC}"
    ./target/release/bitcoin-keyforge --version
    
    echo ""
    echo -e "${GREEN}🎉 All checks passed! Your Bitcoin key management tool is ready.${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  Security Reminders:${NC}"
    echo "   • Only run on air-gapped systems for production keys"
    echo "   • Verify source code before use"
    echo "   • Keep private keys secure"
    echo "   • Test with small amounts first"
    echo ""
else
    echo -e "${RED}❌ Build failed - binary not found${NC}"
    exit 1
fi