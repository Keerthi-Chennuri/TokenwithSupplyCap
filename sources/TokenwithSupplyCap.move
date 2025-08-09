module SC::SupplyCapToken {
    use aptos_framework::signer;
    use std::string;
    use aptos_framework::event;

   
    const E_NOT_OWNER: u64 = 1;
    const E_SUPPLY_CAP_EXCEEDED: u64 = 2;
    const E_INSUFFICIENT_BALANCE: u64 = 3;
    const E_TOKEN_NOT_INITIALIZED: u64 = 4;

   
    struct TokenInfo has store, key {
        name: string::String,           // Token name
        symbol: string::String,         // Token symbol
        total_supply: u64,              // Current total supply
        max_supply: u64,                // Maximum allowed supply
        owner: address,                 // Contract owner who can mint
    }

   
    struct Balance has store, key {
        amount: u64,                    // User's token balance
    }

    
    #[event]
    struct MintEvent has drop, store {
        recipient: address,
        amount: u64,
        new_total_supply: u64,
    }

   
    #[event]
    struct TransferEvent has drop, store {
        from: address,
        to: address,
        amount: u64,
    }

   
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
        
        
        let balance = Balance { amount: 0 };
        move_to(owner, balance);
    }

   
    public fun mint_tokens(
        owner: &signer,
        recipient_signer: &signer,
        amount: u64
    ) acquires TokenInfo, Balance {
        let owner_addr = signer::address_of(owner);
        let recipient = signer::address_of(recipient_signer);
        
        
        assert!(exists<TokenInfo>(owner_addr), E_TOKEN_NOT_INITIALIZED);
        
        let token_info = borrow_global_mut<TokenInfo>(owner_addr);
        
       
        assert!(token_info.owner == owner_addr, E_NOT_OWNER);
        
        
        assert!(token_info.total_supply + amount <= token_info.max_supply, E_SUPPLY_CAP_EXCEEDED);
        
        
        token_info.total_supply = token_info.total_supply + amount;
        
       
        if (!exists<Balance>(recipient)) {
            let balance = Balance { amount: 0 };
            move_to(recipient_signer, balance);
        };
        
        let recipient_balance = borrow_global_mut<Balance>(recipient);
        recipient_balance.amount = recipient_balance.amount + amount;
        
       
        event::emit(MintEvent {
            recipient,
            amount,
            new_total_supply: token_info.total_supply,
        });
    }
}
