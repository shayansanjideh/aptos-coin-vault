module CoinVault::Vault {

    // TODO: Vault struct to store arbitrary number of `ManageCoin`s

    struct Coin has key, store {
        value: u64,
    }

    struct Vault has key {
        coin: Coin
    }

    public fun init_vault(&mut)

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
}