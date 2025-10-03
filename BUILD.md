# 🏗️ Cross-Platform Build Instructions

## Prerequisites

Install Rust and required tools:
```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# Install cross-compilation tools
sudo apt-get update
sudo apt-get install gcc-mingw-w64-x86-64 gcc-mingw-w64-i686 musl-tools

# Add Rust targets
rustup target add x86_64-pc-windows-gnu
rustup target add i686-pc-windows-gnu
rustup target add x86_64-unknown-linux-musl
rustup target add aarch64-unknown-linux-gnu
```

## Quick Release Build (Linux + Windows x64)

Use the provided release script:
```bash
./release.sh
```

This creates optimized binaries for:
- Linux x64 (native)
- Windows x64 (cross-compiled)

## Full Cross-Platform Build

Use the comprehensive cross-build script:
```bash
./cross-build.sh
```

This creates binaries for all supported platforms:
- Linux x64 (native)
- Linux x64-musl (static)
- Linux ARM64
- Windows x64
- Windows x86

## Manual Cross-Compilation

### Linux x64 (Native)
```bash
cargo build --release
```

### Linux x64 (Static - musl)
```bash
cargo build --release --target x86_64-unknown-linux-musl
```

### Windows x64
```bash
CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER=x86_64-w64-mingw32-gcc \
  cargo build --release --target x86_64-pc-windows-gnu
```

### Windows x86
```bash
CARGO_TARGET_I686_PC_WINDOWS_GNU_LINKER=i686-w64-mingw32-gcc \
  cargo build --release --target i686-pc-windows-gnu
```

### Linux ARM64
```bash
# Install cross-compilation toolchain
sudo apt-get install gcc-aarch64-linux-gnu

# Build
CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc \
  cargo build --release --target aarch64-unknown-linux-gnu
```

## Build Outputs

Binaries are located in:
```
target/release/bitcoin-keyforge                    # Linux x64 native
target/x86_64-unknown-linux-musl/release/bitcoin-keyforge   # Linux x64 static
target/x86_64-pc-windows-gnu/release/bitcoin-keyforge.exe   # Windows x64
target/i686-pc-windows-gnu/release/bitcoin-keyforge.exe     # Windows x86
target/aarch64-unknown-linux-gnu/release/bitcoin-keyforge   # Linux ARM64
```

## Release Packaging

Create release packages:
```bash
# Create releases directory
mkdir -p releases

# Package Linux x64
tar -czf releases/bitcoin-keyforge-linux-x64.tar.gz \
  -C target/release bitcoin-keyforge

# Package Linux x64 musl (static)
tar -czf releases/bitcoin-keyforge-linux-x64-musl.tar.gz \
  -C target/x86_64-unknown-linux-musl/release bitcoin-keyforge

# Package Windows x64
zip releases/bitcoin-keyforge-windows-x64.zip \
  target/x86_64-pc-windows-gnu/release/bitcoin-keyforge.exe

# Package Windows x86
zip releases/bitcoin-keyforge-windows-x86.zip \
  target/i686-pc-windows-gnu/release/bitcoin-keyforge.exe

# Package Linux ARM64
tar -czf releases/bitcoin-keyforge-linux-arm64.tar.gz \
  -C target/aarch64-unknown-linux-gnu/release bitcoin-keyforge
```

## Security Notes

- Always build on a clean, trusted machine
- Verify checksums of all release binaries
- Sign binaries before distribution
- Use reproducible builds when possible

## Checksums

Generate SHA256 checksums for verification:
```bash
cd releases
sha256sum *.tar.gz *.zip > SHA256SUMS.txt
```

## GitHub Actions

The project includes automated CI/CD pipelines in `.github/workflows/` that:
- Run tests on every push/PR
- Create cross-platform release builds on version tags
- Generate checksums and release artifacts
- Perform security audits

To trigger a release build, create and push a version tag:
```bash
git tag v1.0.0
git push origin v1.0.0
```