module SC::SupplyCapToken {
    use aptos_framework::signer;
    use std::string;
    use aptos_framework::event;

    /// Error codes
    const E_NOT_OWNER: u64 = 1;
    const E_SUPPLY_CAP_EXCEEDED: u64 = 2;
    const E_INSUFFICIENT_BALANCE: u64 = 3;
    const E_TOKEN_NOT_INITIALIZED: u64 = 4;

    /// Struct representing the token with supply cap
    struct TokenInfo has store, key {
        name: string::String,           // Token name
        symbol: string::String,         // Token symbol
        total_supply: u64,              // Current total supply
        max_supply: u64,                // Maximum allowed supply
        owner: address,                 // Contract owner who can mint
    }

    /// Struct to store user balances
    struct Balance has store, key {
        amount: u64,                    // User's token balance
    }

    /// Event emitted when tokens are minted
    #[event]
    struct MintEvent has drop, store {
        recipient: address,
        amount: u64,
        new_total_supply: u64,
    }

    /// Event emitted when tokens are transferred
    #[event]
    struct TransferEvent has drop, store {
        from: address,
        to: address,
        amount: u64,
    }

    /// Function to initialize the token with name, symbol, and maximum supply
    public fun initialize_token(
        owner: &signer,
        name: string::String,
        symbol: string::String,
        max_supply: u64
    ) {
        let owner_addr = signer::address_of(owner);
        
        let token_info = TokenInfo {
            name,
            symbol,
            total_supply: 0,
            max_supply,
            owner: owner_addr,
        };
        
        move_to(owner, token_info);
        
        // Initialize owner's balance
        let balance = Balance { amount: 0 };
        move_to(owner, balance);
    }

    /// Function to mint new tokens (only owner can mint)
    public fun mint_tokens(
        owner: &signer,
        recipient_signer: &signer,
        amount: u64
    ) acquires TokenInfo, Balance {
        let owner_addr = signer::address_of(owner);
        let recipient = signer::address_of(recipient_signer);
        
        // Check if token is initialized
        assert!(exists<TokenInfo>(owner_addr), E_TOKEN_NOT_INITIALIZED);
        
        let token_info = borrow_global_mut<TokenInfo>(owner_addr);
        
        // Check if caller is the owner
        assert!(token_info.owner == owner_addr, E_NOT_OWNER);
        
        // Check if minting would exceed max supply
        assert!(token_info.total_supply + amount <= token_info.max_supply, E_SUPPLY_CAP_EXCEEDED);
        
        // Update total supply
        token_info.total_supply = token_info.total_supply + amount;
        
        // Add tokens to recipient's balance
        if (!exists<Balance>(recipient)) {
            let balance = Balance { amount: 0 };
            move_to(recipient_signer, balance);
        };
        
        let recipient_balance = borrow_global_mut<Balance>(recipient);
        recipient_balance.amount = recipient_balance.amount + amount;
        
        // Emit mint event
        event::emit(MintEvent {
            recipient,
            amount,
            new_total_supply: token_info.total_supply,
        });
    }
}