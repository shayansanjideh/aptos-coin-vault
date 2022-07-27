module CoinVault::Vault {

    use std::signer;

    use aptos_framework::account;
    use aptos_framework::coin;
    use aptos_framework::managed_coin;


    /// records the address of the user depositing a certain `Managedcoin` in a vault and the number of coins depositied
    struct Share has store {
        user_addr: address,
        // coin: coin::,
        num_coins: u64
    }

    struct Vault has key {
        share_record: vector<Share>,
        total_shares: u64,
        signer_capability: account::SignerCapability,
    }

    const EACCOUNT_NOT_FOUND: u64 = 0;
    const ERESOURCE_DNE: u64 = 1;
    const EINSUFFICIENT_BALANCE: u64 = 2;



}