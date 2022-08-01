module CoinVault::Vault {

    // Uses >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    use std::error;
    use std::signer::address_of;
    use std::vector;

    use aptos_framework::account;
    use aptos_framework::coin::{Self, transfer};

    #[test_only]
    use aptos_framework::managed_coin;

    // Uses <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    // Structs >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // Struct Share represents a user's personal share of the vault
    struct Share has store, drop, key {
        num_coins: u64,
    }

    struct Vault has key {
        share_record: vector<Share>,
        coin_addr: address,
        frozen: bool,
    }

    struct VaultEvent has key {
        resource_addr: address,
    }

    // Structs <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    // Error codes >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    const E_RESOURCE_DNE: u64 = 0;
    const E_FROZEN: u64 = 1;
    const E_INSUFFICIENT_BALANCE: u64 = 2;

    // Error codes <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    // Public entry functions >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    /// Initialize the vault
    public entry fun initialize(source: &signer, seed: vector<u8>, coin_addr: address) {
        let (resource_signer, _resource_signer_cap) = account::create_resource_account(source, seed);

        // Here, resource_signer.address represents the location in global storage of the newly initialized Vault
        // struct. This moves the Vault struct into its newly generated address.
        move_to(
            &resource_signer,
            Vault {
                share_record: vector::empty<Share>(),
                coin_addr,
                frozen: false,
            }
        );

        // Here, source.address represents the location in global storage of the admin/caller's address. This moves the
        // address of the Vault into the admin's account.
        move_to(source, VaultEvent { resource_addr: address_of(&resource_signer) });
    }

    public entry fun deposit<CoinType>(user: &signer, resource_addr: address, amount: u64)
    acquires Vault {
        let user_addr = address_of(user);
        // Check to see if the vault exists
        assert!(exists<Vault>(resource_addr), error::invalid_argument(E_RESOURCE_DNE));

        let vault = borrow_global<Vault>(resource_addr);
        // Check to see if the vault is frozen
        assert!(vault.frozen == false, error::invalid_state(E_FROZEN));

        let user_balance = coin::balance<CoinType>(user_addr);
        // Check to make sure the user can deposit no more coins than they own
        assert!(user_balance > amount, error::out_of_range(E_INSUFFICIENT_BALANCE));

        // Transfer the coins from the user to the vault (resource), and add that number to the user's personal `Share`
        // of the vault
        transfer<CoinType>(user, resource_addr, amount);
        move_to(user, Share { num_coins: amount });
    }

    public entry fun withdraw<CoinType>(user: &signer, resource_signer: &signer, amount: u64)
    acquires Share, Vault {
        let resource_addr = address_of(resource_signer);
        assert!(exists<Vault>(resource_addr), error::invalid_argument(E_RESOURCE_DNE));

        let vault = borrow_global<Vault>(resource_addr);
        assert!(vault.frozen == false, error::invalid_state(E_FROZEN));

        let user_addr = address_of(user);
        let user_balance = borrow_global_mut<Share>(user_addr).num_coins;
        // Check to make sure the user cannot withdraw more coins than they have previously deposited
        assert!(user_balance > amount, error::out_of_range(E_INSUFFICIENT_BALANCE));

        // Transfer the coins from the vault (resource) to the user, and subtract that number from the user's personal
        // `Share` of the vault
        transfer<CoinType>(resource_signer, user_addr, amount);
        move_from<Share>(resource_addr).num_coins;
    }

    // Public entry functions <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    // Private functions >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    /// E-brake: in case of a potential hack, an admin should be able to call the `pause()` function to temporarily
    /// pause all deposits and withdrawals in a vault.
    fun pause<CoinType>(source: &signer)
    acquires Vault {
        let frozen_status = &mut borrow_global_mut<Vault>(address_of(source)).frozen;
        *frozen_status = true;
    }

    fun unpause<CoinType>(source: &signer)
    acquires Vault {
        let frozen_status = &mut borrow_global_mut<Vault>(address_of(source)).frozen;
        *frozen_status = false;
    }

    // Private functions <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    // Tests >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    #[test_only]
    /// VaultCoin struct to be used in tests
    struct VaultCoin {}

    // The admin will be defined by account address 0x1.
    // A user account will have account address 0x2.
    // The address of the test coin, VaultCoin, is @0x3

    #[test(account = @0x1)]
    /// Initialize a coin, initialize a vault, check to make sure it exists, and deposit and withdraw appropriate
    /// amounts of the test coin.
    public fun test_init_dep_with(account: signer)
    acquires Vault {
        // First initialize a test coin, Vault Coin
        managed_coin::initialize<VaultCoin>(
            &account,
            b"Vault Coin",
            b"VTC",
            4,
            true
        );
        assert!(coin::is_coin_initialized<VaultCoin>(), 0);

        managed_coin::register<VaultCoin>(&account);
        let account_addr = address_of(&account);
        managed_coin::mint<VaultCoin>(&account, account_addr, 20);
        assert!(coin::balance<VaultCoin>(account_addr) == 20, 1);

        // Next, initialize the vault itself
        initialize(
            &account,
            b"seed",
            @0x3,
        );

        // Check to see if the vault exists
        assert!(exists<VaultEvent>(account_addr), E_RESOURCE_DNE);

        // deposit some coins into the vault
        deposit<VaultCoin>(account, )
    }

    // Tests <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

}
