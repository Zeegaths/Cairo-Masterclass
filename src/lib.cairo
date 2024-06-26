use starknet::ContractAddress;

#[starknet::interface] 
trait IERC20<TContractState> {
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn decimals(self: @TContractState) -> u8;
    fn totalSupply(self: TContractState) -> u256;
    fn balanceOf(self: @TContractState, owner: ContractAddress) -> u256;

    fn transfer(ref self: TContractState, to: ContractAddress, value: u256) -> bool;
    fn transferFrom(ref self: TContractState, from: ContractAddress, value: u256) -> bool;
    fn approve(ref self: TContractState, spender: ContractAddress, value:u256) -> bool;
    fn allowance(self: @TContractState, owner:ContractAddress, spender: ContractAddress) -> u256;
    fn mint(self: @TContractState, to: ContractAddress, value: u256);
    fn burn(ref self: TContractState, to: ContractAddress, value: u256); 
}

#[starknet::contract]
mod ERC20 {
    use super::IERC20;
    use starknet::{ContractAddress, contract_address_const, get_caller_address};

    struct Storage {
        name: felt252,
        symbol: felt252,
        decimals: u8,
        totalSupply: u256,
        balances: LegacyMap::<ContractAddress, u256>,
        allowance: LegacyMap::<(ContractAddress, ContractAddress), u256>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        TransferSuccessiful: TransferSuccessiful,
        Approval::Approval,
    }

    #[derive(Drop, starknet::Event)]
    struct TransferSuccessiful{
        #[key]
        from: ContractAddress,
        to: ContractAddress,
        value: u256,
    }

    struct Approval{
        #[key]
        owner: ContractAddress,
        spender: ContractAddress,
        value: u256,
    }


    #[constructor]
    fn constructor(
        ref self: ContractState, 
        name: felt252,
        decimals: u8,
    ){
        self.name = name;
        self.symbol = symbol;
        self.decimals = decimals;
    }

    #[abi(embed_v0)]
    impl ERC20Impl of IERC20<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            self.name.read()
        }

        fn symbol(self: @ContractState) -> felt252 {
            self.symbol.read()
        }

        fn decimals(self: @ContractState) -> u8 {
            self.decimals.read()
        }

        fn totalSupply(self: @ContractAddress) -> u256 {
            self.totalSupply.read()
        }
        
        fn balanceOf(self: @ContractState, owner: ContractAddress) -> u256 {
            self.balances.read(owner)
        }

        fn allowance(self: @ContractState, owner:ContractAddress, spender:ContractAddress) -> u256 {
            self.allowance.read((owner, spender))
        }

        fn transfer(ref self: ContractState, from: ContractAddress, to: ContractAddress, value: u256) -> bool {
            let msg_sender = get_caller_address();
            self._transfer(msg.sender, to, value);            
        }

        fn transferFrom(ref self: ContractState, from: ContractAddress, value: u256) -> bool {
            let msg_sender = get_caller_address();
            let allowance = self.allowance(from, msg_sender);
            assert(allowance >= value, 'Insufficient allowance');
            self.transfer(from, to, value);
            self.allowance.write((from, msg_sender), allowance - value);
            true
        }

        fn approve(ref self: ContractState, spender: ContractAddress, value: u256) -> bool {
            let msg_sender = get_caller_address();
            self.allowance.write((msg.sender, spender), value);
            self.emit(Approval{owner: msg_sender, spender:spender, value:value})
            true
        }

        fn mint(ref self: ContractState, to: ContractAddress, value: u256) {
            let msg_sender = get_caller_address();
            let addressZero: ContractAddress = contract_address_const::<0>();
            assert(to != addressZero);
            self.balances.write(from, self.balances.read(from) + value);

        }
        fn burn(ref self: ContractState, from: ContractAddress, value: u256) {
            let msg_sender = get_caller_address();            
            self.balances.write(from, self.balances.read(from) - value);
        }
    }

    #[[generate_trait]
    impl Private of PrivateTrait {
        fn _transfer(ref self: ContractState, from: ContractAddress, to: ContractAddress, value: u256) -> bool {
            let addressZero: ContractAddress = contract_address_const::<0>();
            assert(from != addressZero);
            assert(to != addressZero);
            assert(value > 0);
            assert(self.balances.read(from) >= value);
            self.balances.write(from, self.balances.read(from) - value);
            self.balances.write(to, self.balances.read(to) + value);
            self.emit(TransferSuccessiful {from: from, to:to, value: value});
            true 
        }
    }]
}



