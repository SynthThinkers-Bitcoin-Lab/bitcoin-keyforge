use anyhow::Result;
use bitcoin::{
    key::TapTweak, script::Builder, Address, CompressedPublicKey, Network, NetworkKind,
    PublicKey as BitcoinPublicKey, ScriptBuf, XOnlyPublicKey,
};
use secp256k1::PublicKey;

pub fn generate_all_address_types(
    public_key_hex: &str,
    testnet: bool,
) -> Result<Vec<(String, String)>> {
    let network = if testnet {
        Network::Testnet
    } else {
        Network::Bitcoin
    };
    let network_kind = NetworkKind::from(network);
    let public_key_bytes = hex::decode(public_key_hex)?;
    let secp_public_key = PublicKey::from_slice(&public_key_bytes)?;

    let mut addresses = Vec::new();

    let bitcoin_pubkey = BitcoinPublicKey::new(secp_public_key);

    if let Ok(compressed_pubkey) = CompressedPublicKey::try_from(bitcoin_pubkey) {
        let p2pkh = Address::p2pkh(compressed_pubkey, network_kind);
        addresses.push(("P2PKH (Legacy)".to_string(), p2pkh.to_string()));

        let p2wpkh_script = ScriptBuf::new_p2wpkh(&compressed_pubkey.wpubkey_hash());
        if let Ok(p2sh_p2wpkh) = Address::p2sh(&p2wpkh_script, network_kind) {
            addresses.push((
                "P2SH-P2WPKH (Nested SegWit)".to_string(),
                p2sh_p2wpkh.to_string(),
            ));
        }

        let hrp = bitcoin::KnownHrp::from(network);
        let p2wpkh = Address::p2wpkh(&compressed_pubkey, hrp);
        addresses.push(("P2WPKH (Native SegWit)".to_string(), p2wpkh.to_string()));

        let script = Builder::new()
            .push_slice(compressed_pubkey.to_bytes())
            .push_opcode(bitcoin::opcodes::all::OP_CHECKSIG)
            .into_script();

        if let Ok(p2sh) = Address::p2sh(&script, network_kind) {
            addresses.push(("P2SH (Script Hash)".to_string(), p2sh.to_string()));
        }
    }

    let x_only_pubkey = XOnlyPublicKey::from(secp_public_key);
    let hrp_for_taproot = bitcoin::KnownHrp::from(network);
    let p2tr = Address::p2tr_tweaked(x_only_pubkey.dangerous_assume_tweaked(), hrp_for_taproot);
    addresses.push(("P2TR (Taproot)".to_string(), p2tr.to_string()));

    Ok(addresses)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::crypto::generate_keypair;

    #[test]
    fn test_address_generation() {
        let (_, public_key) = generate_keypair().unwrap();
        let addresses = generate_all_address_types(&public_key, false).unwrap();

        assert!(!addresses.is_empty());
        assert!(addresses.len() >= 4);

        for (addr_type, address) in &addresses {
            assert!(!addr_type.is_empty());
            assert!(!address.is_empty());
            assert!(address.len() > 10);
        }
    }

    #[test]
    fn test_testnet_addresses() {
        let (_, public_key) = generate_keypair().unwrap();
        let mainnet_addresses = generate_all_address_types(&public_key, false).unwrap();
        let testnet_addresses = generate_all_address_types(&public_key, true).unwrap();

        assert_eq!(mainnet_addresses.len(), testnet_addresses.len());

        for (i, ((_, mainnet_addr), (_, testnet_addr))) in mainnet_addresses
            .iter()
            .zip(testnet_addresses.iter())
            .enumerate()
        {
            if i < 3 {
                assert_ne!(
                    mainnet_addr, testnet_addr,
                    "Addresses should differ between networks"
                );
            }
        }
    }
}
