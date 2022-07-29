module CoinVault::Vault {

    use std::error;
    use std::signer;
    use std::vector;

    use aptos_framework::account;
    use aptos_framework::coin::Coin;
    use aptos_framework::managed_coin::Capabilities;

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

    const E_RESOURCE_DNE: u64 = 0;
    const E_FROZEN: u64 = 1;


    public entry fun deposit<CoinType>(depositor: &signer, resource_addr: address, coin: Coin<CoinType>, amount: u64)
    acquires Vault {
        assert!(exists<Vault<CoinType>>(resource_addr), error::invalid_argument(E_RESOURCE_DNE));

        let vault = borrow_global<Vault<CoinType>>(resource_addr);
        let frozen_status = vault.frozen;

        assert!(frozen_status == false, error::invalid_state(E_FROZEN));

        move_to(depositor, Vault<CoinType> {coin, amount, frozen: frozen_status})
    }

    public entry fun withdraw<CoinType>(withdrawor: &signer, resource_addr: address, coin: Coin<CoinType>, amount: u64)
    acquires Vault {
        assert!(exists<Vault<CoinType>>(resource_addr), error::invalid_argument(E_RESOURCE_DNE));

        let vault = borrow_global<Vault<CoinType>>(resource_addr);
        let frozen_status = vault.frozen;

        assert!(frozen_status == false, error::invalid_state(E_FROZEN));

        move_to(withdrawor, Vault<CoinType> {coin, amount, frozen: frozen_status})
    }

    public entry fun pause<CoinType>(source: &signer, resource_addr: address)
    acquires Vault {
        let vault = borrow_global<Vault<CoinType>>(resource_addr);
        let frozen_status = vault.frozen;
        frozen_status = true
    }

    public entry fun unpause<CoinType>(source: &signer, resource_addr: address)
    acquires Vault {
        let vault = borrow_global<Vault<CoinType>>(resource_addr);
        let frozen_status = vault.frozen;
        frozen_status = false
    }
}
