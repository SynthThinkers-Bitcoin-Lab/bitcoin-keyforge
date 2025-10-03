#!/bin/bash
set -euo pipefail

# Source Rust environment if available
if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
fi

echo "🔥 Bitcoin KeyForge - Quick Release Builder"
echo "========================================="

PROJECT_NAME="bitcoin-keyforge"
VERSION=$(grep '^version' Cargo.toml | cut -d'"' -f2)

# Quick build for Linux and Windows
echo "📦 Building for Linux x64 and Windows x64..."

# Install targets if not present
rustup target add x86_64-unknown-linux-gnu 2>/dev/null || true
rustup target add x86_64-pc-windows-gnu 2>/dev/null || true

# Install mingw if needed (Ubuntu/Debian)
if command -v apt-get &> /dev/null && ! command -v x86_64-w64-mingw32-gcc &> /dev/null; then
    echo "📦 Installing Windows cross-compiler..."
    sudo apt-get update -qq && sudo apt-get install -qq -y gcc-mingw-w64-x86-64
fi

mkdir -p releases
cd releases

# Build Linux
echo "🐧 Building Linux x64..."
RUSTFLAGS="-C target-cpu=generic -C strip=symbols" \
    cargo build --release --target=x86_64-unknown-linux-gnu

# Build Windows  
echo "🪟 Building Windows x64..."
CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER=x86_64-w64-mingw32-gcc \
RUSTFLAGS="-C target-cpu=generic -C strip=symbols" \
    cargo build --release --target=x86_64-pc-windows-gnu

# Package releases
echo "📦 Packaging releases..."

# Linux package
mkdir -p ${PROJECT_NAME}-v${VERSION}-linux-x64
cp ../target/x86_64-unknown-linux-gnu/release/${PROJECT_NAME} ${PROJECT_NAME}-v${VERSION}-linux-x64/
cp ../README.md ../LICENSE ${PROJECT_NAME}-v${VERSION}-linux-x64/
tar -czf ${PROJECT_NAME}-v${VERSION}-linux-x64.tar.gz ${PROJECT_NAME}-v${VERSION}-linux-x64
rm -rf ${PROJECT_NAME}-v${VERSION}-linux-x64

# Windows package  
mkdir -p ${PROJECT_NAME}-v${VERSION}-windows-x64
cp ../target/x86_64-pc-windows-gnu/release/${PROJECT_NAME}.exe ${PROJECT_NAME}-v${VERSION}-windows-x64/
cp ../README.md ../LICENSE ${PROJECT_NAME}-v${VERSION}-windows-x64/
zip -r ${PROJECT_NAME}-v${VERSION}-windows-x64.zip ${PROJECT_NAME}-v${VERSION}-windows-x64 >/dev/null
rm -rf ${PROJECT_NAME}-v${VERSION}-windows-x64

# Generate checksums
echo "🔒 Generating checksums..."
sha256sum *.tar.gz *.zip > SHA256SUMS.txt

echo ""
echo "✅ Release packages created:"
ls -la *.tar.gz *.zip *.txt

echo ""
echo "🔒 SHA256 checksums:"
cat SHA256SUMS.txt

cd ..
echo ""
echo "🎉 Quick release build complete! Files are in ./releases/"