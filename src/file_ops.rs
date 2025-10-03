use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::fs::OpenOptions;
use std::io::Write;
use std::path::Path;
use zeroize::ZeroizeOnDrop;

/// Simple key pair structure - only private and public key
#[derive(Serialize, Deserialize, Clone, ZeroizeOnDrop)]
pub struct SimpleKeyPair {
    pub private_key: String,
    pub public_key: String,
}

impl SimpleKeyPair {
    pub fn new(private_key: String, public_key: String) -> Self {
        Self {
            private_key,
            public_key,
        }
    }
}

/// Save simple key pair to file (just private and public key)
pub fn save_simple_key_to_file(
    filename: &str,
    private_key: &str,
    public_key: &str,
) -> Result<()> {
    let path = Path::new(filename);

    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent)?;
    }

    let key_pair = SimpleKeyPair::new(
        private_key.to_string(),
        public_key.to_string(),
    );

    let json_content = serde_json::to_string_pretty(&key_pair)?;

    let mut file = OpenOptions::new()
        .create(true)
        .write(true)
        .truncate(true)
        .open(path)?;

    file.write_all(json_content.as_bytes())?;
    file.sync_all()?;

    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let mut perms = file.metadata()?.permissions();
        perms.set_mode(0o600);
        std::fs::set_permissions(path, perms)?;
    }

    println!("🔒 File permissions set to owner-only (600)");

    Ok(())
}

/// Load private key from simple key file
pub fn load_private_key_from_file(filename: &str) -> Result<String> {
    let path = Path::new(filename);

    if !path.exists() {
        anyhow::bail!("File does not exist: {}", filename);
    }

    let content = std::fs::read_to_string(path)?;

    // Try to parse as SimpleKeyPair JSON
    if let Ok(key_pair) = serde_json::from_str::<SimpleKeyPair>(&content) {
        return Ok(key_pair.private_key.clone());
    }

    // Try to parse as raw hex (64 characters)
    let trimmed = content.trim();
    if trimmed.len() == 64 && hex::decode(trimmed).is_ok() {
        return Ok(trimmed.to_string());
    }

    anyhow::bail!("No valid private key found in file: {}. Expected JSON with private_key field or 64-character hex string.", filename)
}

/// Parse private key from string (hex or file path)
pub fn parse_private_key(input: &str) -> Result<String> {
    // If it looks like a hex key (64 chars), use it directly
    if input.len() == 64 && hex::decode(input).is_ok() {
        return Ok(input.to_string());
    }

    // Otherwise treat as file path
    load_private_key_from_file(input)
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;

    #[test]
    fn test_save_and_load_keys() {
        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("test_keys.json");
        let file_path_str = file_path.to_str().unwrap();

        let private_key = "1111111111111111111111111111111111111111111111111111111111111111";
        let _private_key_wif = "KwDiBf89QgGbjEhKnhXJuH7LrciVrZi3qYjgd9M7rFU73sVHnoWn";
        let public_key = "0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798";
        let _addresses = [
            (
                "P2PKH".to_string(),
                "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2".to_string(),
            ),
            (
                "P2WPKH".to_string(),
                "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4".to_string(),
            ),
        ];

        let result = save_simple_key_to_file(
            file_path_str,
            private_key,
            public_key,
        );
        assert!(result.is_ok());

        let loaded_key = load_private_key_from_file(file_path_str);
        assert!(loaded_key.is_ok());

        let key = loaded_key.unwrap();
        assert_eq!(key, private_key);

        // Test direct hex parsing
        let direct_key = parse_private_key(private_key);
        assert!(direct_key.is_ok());
        assert_eq!(direct_key.unwrap(), private_key);
    }
}
