use anyhow::Result;
use clap::{Parser, Subcommand};

mod bitcoin_address;
mod crypto;
mod file_ops;

use bitcoin_address::generate_all_address_types;
use crypto::{combine_private_keys, generate_keypair, private_key_to_wif};
use file_ops::{parse_private_key, save_simple_key_to_file};

#[derive(Parser)]
#[command(name = "bitcoin-keyforge")]
#[command(about = "Secure Bitcoin key generation and key forging tool")]
#[command(version = "0.1.0")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    #[command(about = "Generate a new Bitcoin keypair")]
    Generate {
        #[arg(short, long, help = "Output file to save keys")]
        output: Option<String>,
        #[arg(long, help = "Generate keys for testnet")]
        testnet: bool,
    },
    #[command(about = "Combine client private key with server auxiliary key for vanity address")]
    Combine {
        #[arg(short, long, help = "Client private key (64-char hex string or file path)")]
        client: String,
        #[arg(
            short,
            long,
            help = "Server auxiliary private key (64-char hex string or file path)",
            required = true
        )]
        auxiliary: String,
        #[arg(short, long, help = "Output file to save combined keys")]
        output: Option<String>,
        #[arg(long, help = "Use testnet")]
        testnet: bool,
    },
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Commands::Generate { output, testnet } => {
            println!("🔐 Generating new Bitcoin keypair...");

            let (private_key, public_key) = generate_keypair()?;
            let addresses = generate_all_address_types(&public_key, testnet)?;
            let wif = private_key_to_wif(&private_key, testnet)?;

            println!("\n✅ Keypair generated successfully!");
            println!("Private Key (Hex): {}", private_key);
            println!("Private Key (WIF): {}", wif);
            println!("Public Key: {}", public_key);

            println!("\n🏠 Generated addresses:");
            for (addr_type, address) in &addresses {
                println!("  {}: {}", addr_type, address);
            }

            if let Some(output_file) = output {
                save_simple_key_to_file(
                    &output_file,
                    &private_key,
                    &public_key,
                )?;
                println!("\n💾 Keys saved to: {}", output_file);
            }
        }


        Commands::Combine {
            client,
            auxiliary,
            output,
            testnet,
        } => {
            println!("🔗 Combining client private key with server auxiliary key for vanity address...");

            // Parse client private key (hex or file)
            let client_private_key = parse_private_key(&client)?;
            if client.len() == 64 {
                println!("  🔑 Using client key from command line");
            } else {
                println!("  📖 Loaded client key from: {}", client);
            }

            // Parse server auxiliary private key (hex or file)
            let server_auxiliary_key = parse_private_key(&auxiliary)?;
            if auxiliary.len() == 64 {
                println!("  🔑 Using server auxiliary key from command line");
            } else {
                println!("  📖 Loaded server auxiliary key from: {}", auxiliary);
            }

            let vanity_private_key = combine_private_keys(&client_private_key, std::slice::from_ref(&server_auxiliary_key))?;
            let vanity_public_key = crypto::private_key_to_public_key(&vanity_private_key)?;
            let vanity_addresses = generate_all_address_types(&vanity_public_key, testnet)?;
            let vanity_wif = private_key_to_wif(&vanity_private_key, testnet)?;

            println!("\n✅ Vanity address keys combined successfully!");
            println!("Client Private Key: {}", client_private_key);
            println!("Server Auxiliary Key: {}", server_auxiliary_key);
            println!("Final Vanity Private Key (Hex): {}", vanity_private_key);
            println!("Final Vanity Private Key (WIF): {}", vanity_wif);
            println!("Vanity Public Key: {}", vanity_public_key);

            println!("\n🏠 Generated vanity addresses:");
            for (addr_type, address) in &vanity_addresses {
                println!("  {}: {}", addr_type, address);
            }

            if let Some(output_file) = output {
                save_simple_key_to_file(
                    &output_file,
                    &vanity_private_key,
                    &vanity_public_key,
                )?;
                println!("\n💾 Vanity keys saved to: {}", output_file);
            }
        }
    }

    Ok(())
}
