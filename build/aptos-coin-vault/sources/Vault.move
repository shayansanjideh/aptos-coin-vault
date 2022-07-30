module CoinVault::Vault {

    // Uses >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    use std::error;
    use std::signer::address_of;

    use aptos_framework::account;
    use aptos_framework::coin::{Self, Coin};

    #[test_only]
    use std::signer;
    #[test_only]
    use aptos_framework::managed_coin;

    // Uses <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    // Structs >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    struct Vault<phantom CoinType> has key {
        coin: Coin<CoinType>,
        amount: u64,
        frozen: bool,
    }

    /// Initialize the vault
    public entry fun initialize<CoinType>(source: &signer, seed: vector<u8>, coin: Coin<CoinType>) {
        let (resource_signer, _resource_signer_cap) = account::create_resource_account(source, seed);

        move_to(
            &resource_signer,
            Vault<CoinType> {
                coin,
                amount: 0,
                frozen: false,
            }
        );
    }

    // Structs <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    // Error codes >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    const E_RESOURCE_DNE: u64 = 0;
    const E_FROZEN: u64 = 1;

    // Error codes <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    // Public entry functions >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    public entry fun deposit<CoinType>(depositor: &signer, resource_addr: address, coin: Coin<CoinType>, amount_dep: u64)
    acquires Vault {
        assert!(exists<Vault<CoinType>>(resource_addr), error::invalid_argument(E_RESOURCE_DNE));

        let vault = borrow_global_mut<Vault<CoinType>>(resource_addr);

        let frozen_status = vault.frozen;
        assert!(frozen_status == false, error::invalid_state(E_FROZEN));

        let amount = vault.amount;
        amount = amount + amount_dep;

        move_to(depositor, Vault<CoinType> {coin, amount, frozen: frozen_status})
    }

    public entry fun withdraw<CoinType>(withdrawor: &signer, resource_addr: address, coin: Coin<CoinType>, amount_with: u64)
    acquires Vault {
        assert!(exists<Vault<CoinType>>(resource_addr), error::invalid_argument(E_RESOURCE_DNE));

        let vault = borrow_global_mut<Vault<CoinType>>(resource_addr);

        let frozen_status = vault.frozen;
        assert!(frozen_status == false, error::invalid_state(E_FROZEN));

        let amount = vault.amount;
        amount = amount - amount_with;

        move_to(withdrawor, Vault<CoinType> {coin, amount, frozen: frozen_status})
    }

    // Public entry functions <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    // Private functions >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    /// E-brake: in case of a potential hack, an admin should be able to call the `pause()` function to temporarily
    /// pause all deposits and withdrawals in a vault.
    fun pause<CoinType>(source: &signer)
    acquires Vault {
        let frozen_status = &mut borrow_global_mut<Vault<CoinType>>(address_of(source)).frozen;
        *frozen_status = true;
    }

    fun unpause<CoinType>(source: &signer)
    acquires Vault {
        let frozen_status = &mut borrow_global_mut<Vault<CoinType>>(address_of(source)).frozen;
        *frozen_status = false;
    }

    // Private functions <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    // Tests >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    #[test_only]
    /// VaultCoin struct to be used in tests
    struct VaultCoin {}

    // The admin will be defined by account address 0x1.
    // Any other account (i.e. a user) will have account address 0x2.

    #[test(account = @0x1)]
    /// Initialize a coin, initialize a vault, and check to make sure it exists
    public fun init_vault_test(account: signer) {
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
        let vault = initialize(
            &signer,
            b"seed",
            VaultCoin,
        );

        // Check to see if the vault exists
        assert!(exists<Vault<VaultCoin>>(account_addr))
    }

    // Tests <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

}
