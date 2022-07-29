module CoinVault::Vault {

    use std::error;
    use std::signer;
    use std::vector;

    use aptos_framework::account;
    use aptos_framework::coin;

    /// Represents a user's share of a vault. Stores the address of the user depositing a certain `Managedcoin` in a
    /// vault and the number of coins depositied
    struct Share has store {
        share_holder: address,
        num_coins: u64
    }

    struct Vault has key {
        share_record: vector<Share>,
        total_coins: u64,
        signer_capability: account::SignerCapability
    }

    struct VaultEvent has key {
        resource_addr: address,
    }

    const EACCOUNT_NOT_FOUND: u64 = 0;
    const ERESOURCE_DNE: u64 = 1;
    const EINSUFFICIENT_BALANCE: u64 = 2;

    /// Initialize the vault
    public entry fun initialize(source: &signer, seed: vector<u8>, addresses: vector<address>, numerators: vector<u64>) {
        let i = 0;
        let total_coins = 0;
        let share_record = vector::empty<Share>();

        let num_coins = *vector::borrow(&numerators, i);
        let share_holder = *vector::borrow(&addresses, i);

        // make sure that the account exists, so when we call deposit()/withdraw() it wouldn't fail
        // because one of the accounts does not exist
        assert!(account::exists_at(share_holder), error::invalid_argument(EACCOUNT_NOT_FOUND));

        vector::push_back(&mut share_record, Share { share_holder, num_coins });
        total_coins = total_coins + num_coins;


        let (resource_signer, resource_signer_cap) = account::create_resource_account(source, seed);

        move_to(
            &resource_signer,
            Vault {
                share_record,
                total_coins,
                signer_capability: resource_signer_cap,
            }
        );

        move_to(source, VaultEvent {
            resource_addr: signer::address_of(&resource_signer)
        });
    }

    public entry fun deposit<CoinType>(resource_signer: &signer, depositor: &signer, num_coins: u64)
    acquires Vault {
        let resource_addr = signer::address_of(resource_signer);
        assert!(exists<Vault>(resource_addr), error::invalid_argument(ERESOURCE_DNE));

        let vault = borrow_global_mut<Vault>(resource_addr);

        let i = vector::length(&vault.share_record);

        let share_record = vault.share_record;
        let total_coins = coin::balance<CoinType>(resource_addr);
        let signer_capability = vault.signer_capability;

        let share_holder = signer::address_of(depositor);

        vector::push_back(&mut share_record, Share { share_holder, num_coins });

        total_coins = total_coins + num_coins;

        move_to(
            resource_signer,
            Vault {
                share_record,
                total_coins,
                signer_capability
            }
        );

        move_to(resource_signer,
            VaultEvent {
                resource_addr
            }
        );

    }

}
