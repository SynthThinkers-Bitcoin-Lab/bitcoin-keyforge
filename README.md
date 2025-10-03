# 🔥 Bitcoin KeyForge

Secure Bitcoin key generation and vanity address split key tool written in Rust.

[![Security](https://img.shields.io/badge/security-high-green.svg)](https://github.com/SynthThinkers-Bitcoin-Lab/bitcoin-keyforge)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Rust](https://img.shields.io/badge/rust-stable-orange.svg)](https://www.rust-lang.org/)

## ⚠️ Security Warning

**This tool handles Bitcoin private keys. Always:**
- Use on an offline, air-gapped machine for production keys
- Verify the source code before use
- Keep private keys secure and never share them
- Make secure backups of important keys
- Test with small amounts first

## 🚀 Features

- **Secure Key Generation**: Cryptographically secure random key generation using OS entropy
- **Vanity Address Split Key**: Secure split key system for generating vanity Bitcoin addresses
- **Key Combination**: Combine client private key with server-computed auxiliary keys
- **Address Generation**: Generate desired vanity Bitcoin addresses through proper key combination
- **Multiple Address Types**: Generate all Bitcoin address formats:
  - P2PKH (Legacy) - `1...`
  - P2SH-P2WPKH (Nested SegWit) - `3...`
  - P2WPKH (Native SegWit) - `bc1q...`
  - P2TR (Taproot) - `bc1p...`
  - P2SH (Script Hash) - `3...`
- **Mainnet & Testnet Support**: Works with both Bitcoin mainnet and testnet
- **Secure File Operations**:
  - Automatic file permission setting (600 - owner only)
  - Simple JSON format (private + public key only)
  - Input validation and sanitization
- **Memory Safety**: Uses `zeroize` crate to securely clear sensitive data
- **Comprehensive Testing**: Full test coverage with security best practices

## 📦 Installation

### Option 1: Download Pre-built Binaries (Recommended)

Download the latest release for your platform from the [Releases page](https://github.com/SynthThinkers-Bitcoin-Lab/bitcoin-keyforge/releases):

| Platform | Architecture | Download |
|----------|-------------|----------|
| 🐧 Linux | x64 | `bitcoin-keyforge-vX.X.X-linux-x64.tar.gz` |
| 🐧 Linux | x64 (musl) | `bitcoin-keyforge-vX.X.X-linux-x64-musl.tar.gz` |
| 🐧 Linux | ARM64 | `bitcoin-keyforge-vX.X.X-linux-arm64.tar.gz` |
| 🪟 Windows | x64 | `bitcoin-keyforge-vX.X.X-windows-x64.zip` |
| 🪟 Windows | x86 | `bitcoin-keyforge-vX.X.X-windows-x86.zip` |

**Always verify checksums:**
```bash
# Download SHA256SUMS.txt and verify
sha256sum -c SHA256SUMS.txt
```

**Extract and run:**
```bash
# Linux
tar -xzf bitcoin-keyforge-*.tar.gz
cd bitcoin-keyforge-*/
./bitcoin-keyforge --help

# Windows
# Extract .zip file and run bitcoin-keyforge.exe
```

### Option 2: Quick Release Build

For local cross-compilation:

```bash
git clone https://github.com/SynthThinkers-Bitcoin-Lab/bitcoin-keyforge.git
cd bitcoin-keyforge
./release.sh  # Builds Linux x64 and Windows x64
```

### Option 3: Full Cross-Compilation

Build for all supported platforms:

```bash
./cross-build.sh  # Builds for 5+ platforms
```

### Option 4: Build from Source

**Prerequisites:**
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
```

**Build:**
```bash
git clone https://github.com/SynthThinkers-Bitcoin-Lab/bitcoin-keyforge.git
cd bitcoin-keyforge
cargo build --release
```

The binary will be available at `./target/release/bitcoin-keyforge`

### Option 5: Install from Crates.io

```bash
cargo install bitcoin-keyforge
```

## 🔧 Usage

### Generate New Keypair

Generate a new Bitcoin keypair and show all address types.

The tool outputs both **hex format** (64 characters) and **WIF format** (Wallet Import Format) for easy import into Bitcoin wallets:

```bash
# Generate new keypair (mainnet)
bitcoin-keyforge generate

# Generate with file output
bitcoin-keyforge generate --output my-keys.json

# Generate for testnet
bitcoin-keyforge generate --testnet --output testnet-keys.json
```

Example output:
```
🔐 Generating new Bitcoin keypair...

✅ Keypair generated successfully!
Private Key (Hex): 93401558e006e45...
Private Key (WIF): L29wqWosJYJ3ZDR...
Public Key: 03260f2f8ff827d...

🏠 Generated addresses:
  P2PKH (Legacy): 1LgfdAcGhzb7Kp4d9Fw8ysLeWyd4QaMsf8
  P2SH-P2WPKH (Nested SegWit): 39kqNTuM9P7cDFZSPPYCru5cU4t99pdTtc
  P2WPKH (Native SegWit): bc1q6l4d4r8l9e375rl9y2eydplp04yaff5evellxn
  P2SH (Script Hash): 39rrVhWXMBMn1KorQyYFBZvR8FmEeQiAoi
  P2TR (Taproot): bc1pyc8jlrlcyld73vdq7xkg6ss2wp8gstzw6jeq43h5tshe586fp6gs0ju3kg
🔒 File permissions set to owner-only (600)

💾 Keys saved to: my-keys.json
```

### Key Combination for Vanity Addresses

**Step 1: Generate client private key**
```bash
bitcoin-keyforge generate --output client.json
```

**Step 2: Share public key with vanity service**
The client sends the public key from `client.json` to the vanity address service.

**Step 3: Combine keys**
The server provides an auxiliary key, and the client combines them:

```bash
# Using key files
bitcoin-keyforge combine --client client.json --auxiliary server_aux.json --output vanity.json

# Using direct hex keys (64 characters each)
bitcoin-keyforge combine \
  --client 93401558e006e45... \
  --auxiliary d14e4e218acecf9... \
  --output vanity.json

# Mixed: file + hex key
bitcoin-keyforge combine --client client.json --auxiliary d14e4e218acecf9...

# For testnet
bitcoin-keyforge combine --client client.json --auxiliary server_aux.json --testnet
```

**Key Input Formats:**
- **File**: JSON file containing private and public keys
- **Hex**: 64-character hexadecimal private key string (e.g., `93401558e006e45...`)

**CLI automatically detects:**
- If input is 64 hex characters → treats as direct private key
- Otherwise → treats as file path and loads key from JSON file

Example output:
```
🔗 Combining client private key with server auxiliary key for vanity address...
  📖 Loaded client key from: client.json
  🔑 Using server auxiliary key from command line

✅ Vanity address keys combined successfully!
Client Private Key: 93401558e006e45...
Server Auxiliary Key: d14e4e218acecf9...
Final Vanity Private Key (Hex): 648e637a6ad5b3e...
Final Vanity Private Key (WIF): KzbBLRagCFg9DTc...
Vanity Public Key: 037f9f45fc49b62...

🏠 Generated vanity addresses:
  P2PKH (Legacy): 19Va5fhjajFCkfTmX5HSnWfnQVKxaLkcvh
  P2WPKH (Native SegWit): bc1qt55ygumwdxc9zdan0h3kgf9nlxqgplvf9zg8zl
  P2TR (Taproot): bc1p0705tlzfkchaf4u95xe0udd3twdvqrv4r3xm0cr9agz3jwhsugqsfwlvqp

💾 Vanity keys saved to: vanity.json
```

## 📁 File Format

Keys are saved in simple JSON format:

```json
{
  "private_key": "93401558e006e45...",
  "public_key": "03260f2f8ff827d..."
}
```

**Note**: When loading from file, only the `private_key` is required. The public key and addresses are automatically computed from the private key.

## 🛡️ Security Features

### Cryptographic Security
- Uses `secp256k1` curve (Bitcoin standard)
- OS-level entropy via `OsRng`
- Secure key combination using elliptic curve arithmetic
- Memory zeroization for sensitive data

### File Security
- Automatic file permissions (600 - owner read/write only)
- Secure backup creation with timestamps
- Input validation and sanitization

### Code Security
- Memory-safe Rust implementation
- Comprehensive error handling
- No unsafe code blocks
- Full test coverage

## 🔥 Vanity Address Split Key Theory

This tool implements the standard vanity address split key system:

1. **Client Key Generation**: Client generates a cryptographically secure private key
2. **Public Key Sharing**: Client shares public key with vanity address service
3. **Server Computation**: Server computes auxiliary private key to achieve desired vanity pattern
4. **Key Combination**: Keys are combined using secp256k1 elliptic curve addition:
   ```
   final_private_key = (client_private_key + server_auxiliary_key) mod n
   ```
   where `n` is the order of the secp256k1 curve

5. **Vanity Address**: The combined key generates the desired vanity Bitcoin address

**Security**: Client retains control of their private key throughout the process. Server cannot access client's funds without the auxiliary key.

## 🧪 Testing

Run the test suite:

```bash
# Run all tests
cargo test

# Run with output
cargo test -- --nocapture

# Run specific module tests
cargo test crypto::tests
cargo test bitcoin_address::tests
cargo test file_ops::tests
```

## 🏗️ Development

### Project Structure

```
src/
├── main.rs              # CLI interface and main application logic
├── crypto.rs            # Cryptographic operations (key generation, combination)
├── bitcoin_address.rs   # Bitcoin address generation for all types
└── file_ops.rs          # Secure file operations and serialization
```

### Cross-Platform Builds

The project supports cross-compilation for multiple platforms:

**Quick build (Linux + Windows x64):**
```bash
./release.sh
```

**Full cross-compilation:**
```bash
./cross-build.sh  # Builds for all supported platforms
```

**Manual cross-compilation:**
```bash
# Install targets
rustup target add x86_64-pc-windows-gnu
rustup target add x86_64-unknown-linux-musl

# Install cross-compilation tools (Ubuntu/Debian)
sudo apt-get install gcc-mingw-w64-x86-64 musl-tools

# Build for Windows
CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER=x86_64-w64-mingw32-gcc \
  cargo build --release --target x86_64-pc-windows-gnu

# Build for Linux (musl)
cargo build --release --target x86_64-unknown-linux-musl
```

### Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`  
3. Write tests for new functionality
4. Ensure all tests pass: `cargo test`
5. Run clippy: `cargo clippy -- -D warnings`
6. Format code: `cargo fmt`
7. Test cross-compilation: `./release.sh`
8. Submit a pull request

### Automated Releases

The project uses GitHub Actions for automated cross-platform builds:

- **CI Pipeline**: Tests, linting, security audit on every push/PR
- **Release Pipeline**: Triggered on version tags (e.g., `v1.0.0`)
- **Platforms**: Linux (x64, ARM64, musl), Windows (x64, x86)
- **Artifacts**: Pre-built binaries with checksums for each platform

### Code Quality

This project follows strict security and quality standards:

- **Security**: All cryptographic operations use audited libraries
- **Memory Safety**: Rust's ownership system + zeroization
- **Error Handling**: Comprehensive error propagation with `anyhow`
- **Testing**: Full test coverage including edge cases
- **Documentation**: Comprehensive inline and external documentation

## ⚖️ License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🚨 Disclaimer

This software is provided "as is", without warranty of any kind. Users are responsible for:

- Verifying the security and correctness of the implementation
- Safely storing and managing their private keys
- Understanding the risks associated with cryptocurrency operations
- Testing thoroughly before using with real funds

**Always verify addresses and test with small amounts first.**

## 🔑 Private Key Import

See **[PKEYIMPORT.md](PKEYIMPORT.md)** for detailed instructions on importing generated private keys into various Bitcoin wallets including:

- Desktop wallets (Bitcoin Core, Electrum, Sparrow)
- Mobile wallets (BlueWallet, Samourai, Mycelium)
- Web wallets and Lightning wallets
- Security best practices and troubleshooting

## 🤝 Support

- 📖 [Documentation](https://github.com/SynthThinkers-Bitcoin-Lab/bitcoin-keyforge/wiki)
- 🔑 [Private Key Import Guide](PKEYIMPORT.md)
- 🐛 [Bug Reports](https://github.com/SynthThinkers-Bitcoin-Lab/bitcoin-keyforge/issues)
- 💡 [Feature Requests](https://github.com/SynthThinkers-Bitcoin-Lab/bitcoin-keyforge/issues)
- 🔒 [Security Issues](https://github.com/SynthThinkers-Bitcoin-Lab/bitcoin-keyforge/security/advisories)

---

**⚠️ Always keep your private keys secure and never share them with anyone! ⚠️**
