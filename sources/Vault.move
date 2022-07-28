module CoinVault::Vault {

    use std::error;
    use std::signer;
    use std::vector::empty;

    use aptos_framework::coin::Coin;

    struct ManagedCoin has store {}

    /// Represents a user's share of a vault. Stores the address of the user depositing a certain `Managedcoin` in a
    /// vault and the number of coins depositied
    struct Share has store {
        user_addr: address,
        coin_name: Coin<ManagedCoin>,
        num_coins: u64
    }

    struct Vault has key {
        share_record: vector<Share>,
        coin_name: Coin<ManagedCoin>,
        total_coins: u64,
    }

    const EALREADY_INIT: u64 = 0;

    /// Initialize the vault
    public entry fun init_vault(creator: &signer, coin_name: Coin<ManagedCoin>) {

    }


}