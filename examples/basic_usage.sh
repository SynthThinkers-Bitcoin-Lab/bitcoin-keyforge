#!/bin/bash
# Basic usage examples for Bitcoin KeyForge

echo "🔥 Bitcoin KeyForge - Basic Usage Examples"
echo "========================================="
echo ""

# Make sure we have the binary
if [[ ! -f "../target/release/bitcoin-keyforge" ]]; then
    echo "❌ Please build the project first: cargo build --release"
    exit 1
fi

BITCOIN_KEYFORGE="../target/release/bitcoin-keyforge"

echo "1️⃣ Generate a single Bitcoin keypair:"
echo "   $BITCOIN_KEYFORGE generate"
echo ""
$BITCOIN_KEYFORGE generate

echo ""
echo "2️⃣ Generate keypair and save to file:"
echo "   $BITCOIN_KEYFORGE generate --output my-wallet.json"
echo ""
$BITCOIN_KEYFORGE generate --output example-wallet.json

echo ""
echo "3️⃣ Generate testnet keypair:"
echo "   $BITCOIN_KEYFORGE generate --testnet"
echo ""
$BITCOIN_KEYFORGE generate --testnet

echo ""
echo "4️⃣ Generate another keypair for combining:"
echo "   $BITCOIN_KEYFORGE generate --output wallet2.json"
echo ""
$BITCOIN_KEYFORGE generate --output example-wallet2.json

echo ""
echo "5️⃣ Combine two private keys:"
echo "   $BITCOIN_KEYFORGE combine --input example-wallet.json --input example-wallet2.json --output combined-wallet.json"
echo ""
$BITCOIN_KEYFORGE combine --input example-wallet.json --input example-wallet2.json --output combined-wallet.json

echo ""
echo "6️⃣ Show help for all commands:"
echo "   $BITCOIN_KEYFORGE --help"
echo ""
$BITCOIN_KEYFORGE --help

echo ""
echo "🧹 Cleaning up example files..."
rm -f example-wallet.json example-wallet2.json combined-wallet.json

echo ""
echo "✅ Basic usage examples completed!"
echo ""
echo "⚠️  Remember: Never use generated keys from examples for real Bitcoin!"
echo "   Always generate fresh keys on a secure, air-gapped system."