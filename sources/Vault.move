module CoinVault::Vault {

    use aptos_framework::coin;

    use std::string;

    /// Name of
    struct Coin has key, store {
        name: std::string,
        value: u64,
    }

    // TODO: Vault struct to store arbitrary number of `ManageCoin`s

    /// Struct for vault
    struct Vault has key {
        coin: Coin
    }


    // TODO: Deposit and Withdraw functions: users can only deposit/withdraw their own funds and not other users'

    public fun deposit(coin: &mut Coin, vault: &mut Vault, amount: u64): Vault {
        coin.value = coin.value - amount;
        vault.coin = coin.value + amount
    }

    public fun withdraw(coin: &mut Coin, vault: &mut Vault, amount: u64): Coin {
        vault.coin = coin.value - amount;
        coin.value = coin.value + amount
    }


    // TODO: Admin only functions: Pause and Unpause
    /// Emergency stop: pause and unpause all trading
    public fun pause() {
        // If user calls either the deposit or withdraw functions, abort it
    }

    public fun unpause() {
        // Undo pause function
    }


    //TODO: Tests

    #[test]
    fun deposit_test() {
        assert!()
    }

    #[test]
    fun withdraw_test() {
        assert!()
    }
}