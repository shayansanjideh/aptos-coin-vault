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
    const E_INCORRECT_BALANCE: u64 = 3;

    // Error codes <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    // Public entry functions >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    /// Initialize the vault
    public entry fun initialize(source: &signer, seed: vector<u8>, coin_addr: address): signer {
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
        let resource_addr = address_of(&resource_signer);
        move_to(source, VaultEvent { resource_addr });
        resource_signer
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

        // Shadow user_balance, update its value in global storage
        let user_balance = &mut borrow_global_mut<Share>(user_addr).num_coins;
        *user_balance = *user_balance - amount;
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
    /// TestCoin struct to be used in tests
    struct TestCoin {}

    // The admin will be defined by account address 0x1.
    // A user account will have account address 0x2.
    // The address of the test coin, TestCoin, is @0x3

    #[test(account = @0x1)]
    /// Initialize a coin, initialize a vault, check to make sure it exists, and deposit and withdraw appropriate
    /// amounts of the test coin.
    public fun test_init_dep_with(account: signer)
    acquires Vault, Share {
        // First initialize a test coin, Vault Coin
        managed_coin::initialize<TestCoin>(
            &account,
            b"TestCoin",
            b"TST",
            4,
            true
        );
        assert!(coin::is_coin_initialized<TestCoin>(), 0);

        managed_coin::register<TestCoin>(&account);
        let account_addr = address_of(&account);
        managed_coin::mint<TestCoin>(&account, account_addr, 20);
        assert!(coin::balance<TestCoin>(account_addr) == 20, 1);

        // Next, initialize the vault itself
        let resource_signer = initialize(
            &account,
            b"seed",
            @0x3,
        );

        let resource_addr = address_of(&resource_signer);

        // Check to see if the vault exists
        assert!(exists<Vault>(resource_addr), E_RESOURCE_DNE);

        // deposit some coins into the vault
        managed_coin::register<TestCoin>(&resource_signer);
        deposit<TestCoin>(&account, resource_addr, 15);
        assert!(coin::balance<TestCoin>(account_addr) == 5 &&
                coin::balance<TestCoin>(resource_addr) == 15, E_INCORRECT_BALANCE);

        // withdraw some coins back into your own account
        withdraw<TestCoin>(&account, &resource_signer, 10);
        assert!(coin::balance<TestCoin>(account_addr) == 15 &&
                coin::balance<TestCoin>(resource_addr) == 5, E_INCORRECT_BALANCE);
    }

    #[test(account = @0x1)]
    #[expected_failure]
    public fun test_with_more_than_dep(account: signer)
    acquires Vault, Share {
        // Repeat same steps as above, up to the withdrawal part
        managed_coin::initialize<TestCoin>(
            &account,
            b"TestCoin",
            b"TST",
            4,
            true
        );
        assert!(coin::is_coin_initialized<TestCoin>(), 0);

        managed_coin::register<TestCoin>(&account);
        let account_addr = address_of(&account);
        managed_coin::mint<TestCoin>(&account, account_addr, 20);
        assert!(coin::balance<TestCoin>(account_addr) == 20, 1);

        let resource_signer = initialize(
            &account,
            b"seed",
            @0x3,
        );

        let resource_addr = address_of(&resource_signer);

        assert!(exists<Vault>(resource_addr), E_RESOURCE_DNE);

        managed_coin::register<TestCoin>(&resource_signer);
        deposit<TestCoin>(&account, resource_addr, 15);
        assert!(coin::balance<TestCoin>(account_addr) == 5 &&
                coin::balance<TestCoin>(resource_addr) == 15, E_INCORRECT_BALANCE);

        // withdraw more coins into your account than you deposited
        withdraw<TestCoin>(&account, &resource_signer, 17);
    }

    #[test(account1 = @0x1, account2 = @0x2)]
    #[expected_failure]
    public fun test_with_someone_else_dep(account1: signer, account2: signer)
    acquires Vault, Share {
        // Repeat same steps as above, up to the withdrawal part
        managed_coin::initialize<TestCoin>(
            &account1,
            b"TestCoin",
            b"TST",
            4,
            true
        );
        assert!(coin::is_coin_initialized<TestCoin>(), 0);

        managed_coin::register<TestCoin>(&account1);
        managed_coin::register<TestCoin>(&account2);
        let account_addr1 = address_of(&account1);
        managed_coin::mint<TestCoin>(&account1, account_addr1, 20);
        assert!(coin::balance<TestCoin>(account_addr1) == 20, 1);

        let resource_signer = initialize(
            &account1,
            b"seed",
            @0x3,
        );

        let resource_addr = address_of(&resource_signer);

        assert!(exists<Vault>(resource_addr), E_RESOURCE_DNE);

        managed_coin::register<TestCoin>(&resource_signer);
        deposit<TestCoin>(&account1, resource_addr, 15);
        assert!(coin::balance<TestCoin>(account_addr1) == 5 &&
                coin::balance<TestCoin>(resource_addr) == 15, E_INCORRECT_BALANCE);

        // Try to withdraw account1's coins into account2's account
        withdraw<TestCoin>(&account2, &resource_signer, 17);
    }

    // Tests <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

}
