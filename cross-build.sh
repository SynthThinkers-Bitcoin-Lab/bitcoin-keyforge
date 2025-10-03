#!/bin/bash
set -euo pipefail

# Source Rust environment if available
if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
fi

echo "🔥 Bitcoin KeyForge - Cross-Platform Release Builder"
echo "=================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Project info
PROJECT_NAME="bitcoin-keyforge"
VERSION=$(grep '^version' Cargo.toml | cut -d'"' -f2)
RELEASE_DIR="releases"

# Target platforms
TARGETS=(
    "x86_64-unknown-linux-gnu"      # Linux 64-bit
    "x86_64-unknown-linux-musl"     # Linux 64-bit (static)
    "aarch64-unknown-linux-gnu"     # Linux ARM64
    "x86_64-pc-windows-gnu"         # Windows 64-bit
    "i686-pc-windows-gnu"           # Windows 32-bit
)

echo -e "${BLUE}📦 Project: $PROJECT_NAME v$VERSION${NC}"
echo -e "${BLUE}🎯 Building for ${#TARGETS[@]} target platforms${NC}"
echo ""

# Check if Rust is installed
if ! command -v cargo &> /dev/null; then
    echo -e "${RED}❌ Rust/Cargo not found. Please install Rust first${NC}"
    exit 1
fi

# Install required tools
echo -e "${YELLOW}🔧 Installing cross-compilation tools...${NC}"
rustup target add x86_64-unknown-linux-gnu
rustup target add x86_64-unknown-linux-musl
rustup target add aarch64-unknown-linux-gnu
rustup target add x86_64-pc-windows-gnu
rustup target add i686-pc-windows-gnu

# Check and install cross-compilation dependencies
echo -e "${YELLOW}📦 Checking cross-compilation dependencies...${NC}"

# Check if required tools are already installed
MISSING_TOOLS=()

if ! command -v x86_64-w64-mingw32-gcc &> /dev/null; then
    MISSING_TOOLS+=("gcc-mingw-w64-x86-64")
fi

if ! command -v i686-w64-mingw32-gcc &> /dev/null; then
    MISSING_TOOLS+=("gcc-mingw-w64-i686")
fi

if ! command -v aarch64-linux-gnu-gcc &> /dev/null; then
    MISSING_TOOLS+=("gcc-aarch64-linux-gnu")
fi

if ! command -v musl-gcc &> /dev/null; then
    MISSING_TOOLS+=("musl-tools musl-dev")
fi

if [ ${#MISSING_TOOLS[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ All cross-compilation tools already installed${NC}"
else
    echo -e "${YELLOW}⚠️  Missing tools: ${MISSING_TOOLS[*]}${NC}"
    echo -e "${YELLOW}📦 Installing missing cross-compilation dependencies...${NC}"

    if command -v apt-get &> /dev/null; then
        echo "Running: sudo apt-get update && sudo apt-get install ${MISSING_TOOLS[*]}"
        echo "Please run manually if needed, continuing with available tools..."
    elif command -v dnf &> /dev/null; then
        echo "Please install missing tools: sudo dnf install ${MISSING_TOOLS[*]}"
    elif command -v pacman &> /dev/null; then
        echo "Please install missing tools: sudo pacman -S ${MISSING_TOOLS[*]}"
    else
        echo -e "${YELLOW}⚠️  Could not detect package manager. Please install missing tools manually.${NC}"
    fi
fi

# Create release directory
mkdir -p "$RELEASE_DIR"
rm -rf "$RELEASE_DIR"/*

echo ""
echo -e "${PURPLE}🏗️  Starting cross-compilation builds...${NC}"

# Function to build for a specific target
build_target() {
    local target=$1
    local target_name
    local binary_name="$PROJECT_NAME"
    
    case $target in
        *windows*)
            binary_name="${PROJECT_NAME}.exe"
            ;;
    esac
    
    # Create target-specific name
    case $target in
        "x86_64-unknown-linux-gnu")
            target_name="linux-x64"
            ;;
        "x86_64-unknown-linux-musl")
            target_name="linux-x64-musl"
            ;;
        "aarch64-unknown-linux-gnu")
            target_name="linux-arm64"
            ;;
        "x86_64-pc-windows-gnu")
            target_name="windows-x64"
            ;;
        "i686-pc-windows-gnu")
            target_name="windows-x86"
            ;;
        *)
            target_name=$target
            ;;
    esac
    
    echo -e "${BLUE}🔨 Building for $target ($target_name)...${NC}"
    
    # Set cross-compilation environment variables
    export CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER=x86_64-w64-mingw32-gcc
    export CARGO_TARGET_I686_PC_WINDOWS_GNU_LINKER=i686-w64-mingw32-gcc
    export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc
    
    # Build with optimizations
    # Special handling for 32-bit Windows (requires SSE for SIMD types)
    if [[ "$target" == "i686-pc-windows-gnu" ]]; then
        RUSTFLAGS="-C target-cpu=generic -C target-feature=+sse,+sse2 -C link-dead-code -C strip=symbols" \
            cargo build --release --target="$target" --locked
    else
        RUSTFLAGS="-C target-cpu=generic -C link-dead-code -C strip=symbols" \
            cargo build --release --target="$target" --locked
    fi
    
    if [[ $? -eq 0 ]]; then
        # Create release archive
        local archive_name="${PROJECT_NAME}-v${VERSION}-${target_name}"
        local temp_dir="$RELEASE_DIR/$archive_name"
        
        mkdir -p "$temp_dir"
        
        # Copy binary
        cp "target/$target/release/$binary_name" "$temp_dir/"
        
        # Copy documentation
        cp README.md "$temp_dir/"
        cp LICENSE "$temp_dir/"
        
        # Create usage instructions
        cat > "$temp_dir/USAGE.txt" << EOF
Bitcoin KeyForge v$VERSION - $target_name

Usage:
  ./$binary_name generate                           Generate new keypair
  ./$binary_name generate --output keys.json       Save to file
  ./$binary_name generate --testnet               Generate for testnet
  ./$binary_name combine --client key1.json --auxiliary key2.json    Combine keys from files
  ./$binary_name combine --client HEX_KEY --auxiliary HEX_KEY        Combine hex keys directly
  ./$binary_name --help                           Show all options

Key Formats:
- File: JSON containing private_key and public_key
- Hex:  64-character hexadecimal private key string

Security:
- Only use on air-gapped systems for production keys
- Keep private keys secure and never share them
- Verify checksums before use
- Test with small amounts first

Project: https://github.com/SynthThinkers-Bitcoin-Lab/$PROJECT_NAME
EOF
        
        # Create archive
        cd "$RELEASE_DIR"
        tar -czf "${archive_name}.tar.gz" "$archive_name"
        zip -r "${archive_name}.zip" "$archive_name" > /dev/null 2>&1
        
        # Generate checksums
        sha256sum "${archive_name}.tar.gz" >> "SHA256SUMS.txt"
        sha256sum "${archive_name}.zip" >> "SHA256SUMS.txt"
        
        # Clean up temp directory
        rm -rf "$archive_name"
        
        cd ..
        
        echo -e "${GREEN}✅ Built $target_name successfully${NC}"
    else
        echo -e "${RED}❌ Failed to build $target_name${NC}"
        return 1
    fi
}

# Build for all targets
failed_builds=()
for target in "${TARGETS[@]}"; do
    if ! build_target "$target"; then
        failed_builds+=("$target")
    fi
    echo ""
done

# Generate release notes
cat > "$RELEASE_DIR/RELEASE_NOTES.md" << EOF
# Bitcoin KeyForge v$VERSION Release

## 📦 Downloads

| Platform | Architecture | Download |
|----------|-------------|----------|
| Linux | x64 | [\`$PROJECT_NAME-v$VERSION-linux-x64.tar.gz\`]($PROJECT_NAME-v$VERSION-linux-x64.tar.gz) |
| Linux | x64 (musl) | [\`$PROJECT_NAME-v$VERSION-linux-x64-musl.tar.gz\`]($PROJECT_NAME-v$VERSION-linux-x64-musl.tar.gz) |
| Linux | ARM64 | [\`$PROJECT_NAME-v$VERSION-linux-arm64.tar.gz\`]($PROJECT_NAME-v$VERSION-linux-arm64.tar.gz) |
| Windows | x64 | [\`$PROJECT_NAME-v$VERSION-windows-x64.zip\`]($PROJECT_NAME-v$VERSION-windows-x64.zip) |
| Windows | x86 | [\`$PROJECT_NAME-v$VERSION-windows-x86.zip\`]($PROJECT_NAME-v$VERSION-windows-x86.zip) |

## 🔒 Security

**SHA256 Checksums:**
\`\`\`
$(cat "$RELEASE_DIR/SHA256SUMS.txt")
\`\`\`

## ⚠️ Security Warnings

- **NEVER** use this tool on internet-connected systems for production Bitcoin keys
- **ALWAYS** verify checksums before running
- **ONLY** use on air-gapped, secure systems for real Bitcoin operations  
- **TEST** thoroughly with testnet before mainnet use

## 🚀 Features

- Generate cryptographically secure Bitcoin private/public keypairs
- Combine multiple private keys (split key reconstruction)
- Support for all major Bitcoin address types (P2PKH, P2WPKH, P2TR, etc.)
- Mainnet and testnet support
- Secure file operations with automatic permissions
- Memory-safe Rust implementation with zeroization

## 📖 Usage

Extract the archive and run:

\`\`\`bash
# Generate new keys
./bitcoin-keyforge generate

# Save to file
./bitcoin-keyforge generate --output wallet.json

# Combine keys (vanity address)
./bitcoin-keyforge combine --client client.json --auxiliary server_aux.json

# Combine with hex keys directly
./bitcoin-keyforge combine --client HEX_KEY --auxiliary HEX_KEY

# Show help
./bitcoin-keyforge --help
\`\`\`

For detailed documentation, see [README.md](README.md).

---
Built with ❤️  and maximum security in mind.
EOF

# Summary
echo -e "${PURPLE}📊 Build Summary${NC}"
echo "================"
echo -e "${GREEN}✅ Successfully built: $((${#TARGETS[@]} - ${#failed_builds[@]}))/${#TARGETS[@]} targets${NC}"

if [[ ${#failed_builds[@]} -gt 0 ]]; then
    echo -e "${RED}❌ Failed builds:${NC}"
    for failed in "${failed_builds[@]}"; do
        echo -e "   • $failed"
    done
fi

echo ""
echo -e "${GREEN}🎉 Release files created in: ./$RELEASE_DIR/${NC}"
echo ""
ls -la "$RELEASE_DIR"

echo ""
echo -e "${YELLOW}🚀 Next steps:${NC}"
echo "1. Verify all binaries work correctly"
echo "2. Test checksums"
echo "3. Upload to GitHub Releases"
echo "4. Update documentation"
echo ""
echo -e "${GREEN}✅ Cross-compilation complete!${NC}"