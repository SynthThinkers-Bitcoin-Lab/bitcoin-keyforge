# Makefile for BTC Split Key

.PHONY: build release test clean install help

# Default target
help:
	@echo "BTC Split Key - Available commands:"
	@echo ""
	@echo "Building:"
	@echo "  build          - Build debug version"
	@echo "  release        - Build optimized release version"
	@echo "  quick-release  - Build Linux x64 + Windows x64 releases"
	@echo "  cross-build    - Build for all supported platforms"
	@echo ""
	@echo "Cross-compilation:"
	@echo "  install-targets     - Install Rust targets for cross-compilation"
	@echo "  install-cross-tools - Install system cross-compilation tools"
	@echo "  setup-cross         - Setup complete cross-compilation environment"
	@echo ""
	@echo "Development:"
	@echo "  test      - Run all tests"
	@echo "  format    - Format code with rustfmt"
	@echo "  lint      - Run clippy linter"
	@echo "  check     - Quick check (build + test)"
	@echo "  audit     - Run security audit"
	@echo ""
	@echo "Other:"
	@echo "  clean     - Clean build artifacts"
	@echo "  install   - Install to system (requires cargo)"
	@echo "  docs      - Generate documentation"
	@echo "  demo      - Show demo of key generation"
	@echo ""

# Build debug version
build:
	cargo build

# Build release version
release:
	cargo build --release
	@echo ""
	@echo "✅ Release binary built: ./target/release/bitcoin-keyforge"
	@echo ""

# Run tests
test:
	cargo test

# Clean build artifacts
clean:
	cargo clean

# Install to system
install:
	cargo install --path .

# Format code
format:
	cargo fmt

# Run linter
lint:
	cargo clippy -- -D warnings

# Generate documentation
docs:
	cargo doc --no-deps --open

# Quick build and test
check:
	cargo check
	cargo test

# Security audit (requires cargo-audit)
audit:
	cargo audit

# Cross-platform release build
cross-build:
	./cross-build.sh

# Quick release (Linux + Windows x64)
quick-release:
	./release.sh

# Generate example usage
demo: release
	@echo "🔐 Demo: Generating Bitcoin keys..."
	@echo ""
	./target/release/bitcoin-keyforge generate
	@echo ""
	@echo "📝 For more options, run: ./target/release/bitcoin-keyforge --help"

# Install cross-compilation targets
install-targets:
	rustup target add x86_64-unknown-linux-gnu
	rustup target add x86_64-unknown-linux-musl
	rustup target add aarch64-unknown-linux-gnu
	rustup target add x86_64-pc-windows-gnu
	rustup target add i686-pc-windows-gnu

# Install cross-compilation tools (Ubuntu/Debian)
install-cross-tools:
	sudo apt-get update -qq
	sudo apt-get install -qq -y \
		gcc-mingw-w64-x86-64 \
		gcc-mingw-w64-i686 \
		gcc-aarch64-linux-gnu \
		musl-tools \
		musl-dev

# Setup cross-compilation environment
setup-cross: install-targets install-cross-tools
	@echo "✅ Cross-compilation environment set up!"