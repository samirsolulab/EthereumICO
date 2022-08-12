// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8 <0.9.0;
// ERC-20 Token Standard
// -----------------------------------------instance is called ERC20Interface
interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);
    
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// The Plutos Token Contract
contract Plutos is ERC20Interface{
    string public name = "Nicotex";
    string public symbol = "NTX";
    uint public decimals = 0;
    uint public override totalSupply;
    
    address public founder;
    mapping(address => uint) public balances;

    mapping(address => mapping(address => uint)) allowed;

    
    
    constructor(){
        totalSupply = 100000000; //100 Million
        founder = msg.sender;
        balances[founder] = totalSupply;
    }    
    
    function balanceOf(address tokenOwner) public view override returns (uint balance){
        return balances[tokenOwner];
    }    
    
    function transfer(address to, uint tokens) public virtual override returns(bool success){
        require(balances[msg.sender] >= tokens);
        
        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, to, tokens);
        
        return true;
    }    
    
    function allowance(address tokenOwner, address spender) public view override returns(uint){
        return allowed[tokenOwner][spender];
    }    
    
    function approve(address spender, uint tokens) public override returns (bool success){
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);
        
        allowed[msg.sender][spender] = tokens;
        
        emit Approval(msg.sender, spender, tokens);
        return true;
    }    
    
    function transferFrom(address from, address to, uint tokens) public virtual override returns (bool success){
         require(allowed[from][to] >= tokens);
         require(balances[from] >= tokens);
         
         balances[from] -= tokens;
         balances[to] += tokens;
         allowed[from][to] -= tokens;
         
         return true;
     }
}


contract PlutosICO is Plutos{
    address public admin;
    address payable public deposit;
    uint preSaletokenPrice = 0.0000085 ether;  //0.015 dollars = 0.0000085 Ether
    uint public preSalehardCap = 30000000;
    uint public preSaleCount = 0;
    uint public raisedAmount; // THIS VALUE  WILL BE IN wei
    uint public preSaleStart = block.timestamp;
    uint public preSaleEnd = block.timestamp + 1660028878; //ONE WEEK OF PRESALE

    uint seedSaletokenPrice = 0.000014 ether;  //0.025 dollars = 0.000014 Ether
    uint public seedSalehardCap = 50000000;
    uint public seedSaleCount = 0;
    uint public seedSaleStart = block.timestamp + 3320057756; // AFTER ONE WEEK OF PRESALE
    uint public seedSaleEnd = block.timestamp + 6640115512; // TWO WEEKS FOR SEEDSALE
    
    uint public maxInvestment = 5 ether;
    uint public minInvestment = 0.015 ether;
    
    enum State { beforeStart, running, afterEnd, halted} // ICO states 
    State public preSaleState;
    State public seedSaleState;
    
    constructor(address payable _deposit){
        deposit = _deposit; 
        admin = msg.sender; 
        preSaleState = State.beforeStart;
        seedSaleState =State.beforeStart;
    }
    
    modifier onlyAdmin(){
        require(msg.sender == admin, 'Only Admin Can Call');
        _;
    }    
    
    // Emergency Halt
    function preSalehalt() public onlyAdmin{
        preSaleState = State.halted;
    }    
    
    function preSaleresume() public onlyAdmin{
        preSaleState = State.running;
    }    

        function seedSalehalt() public onlyAdmin{
        preSaleState = State.halted;
    }    
    
    function seedSaleresume() public onlyAdmin{
        preSaleState = State.running;
    } 
    
    function changeDepositAddress(address payable newDeposit) public onlyAdmin{
        deposit = newDeposit;
    }    
    
    function getPreSaleCurrentState() public view returns(State){
        if(preSaleState == State.halted){
            return State.halted;
        }else if(block.timestamp < preSaleStart){
            return State.beforeStart;
        }else if(block.timestamp >= preSaleStart && block.timestamp <= preSaleEnd){
            return State.running;
        }else{
            return State.afterEnd;
        }
    }

    function getSeedSaleCurrentState() public view returns(State){
        if(seedSaleState == State.halted){
            return State.halted;
        }else if(block.timestamp < seedSaleStart){
            return State.beforeStart;
        }else if(block.timestamp >= seedSaleStart && block.timestamp <= seedSaleEnd){
            return State.running;
        }else{
            return State.afterEnd;
        }
    }

    event PreSale(address investor, uint value, uint tokens);    
    event SeedSale(address investor, uint value, uint tokens); 
    
    // Function Called When Sending Eth To The Contract
    function preSale() payable public returns(bool){ 
        preSaleState = getPreSaleCurrentState();
        
        require(preSaleState == State.running,'PreSale not running now');
        require(msg.value >= minInvestment && msg.value <= maxInvestment);
        require(preSaleCount <= preSalehardCap);
        
        raisedAmount += msg.value;
        uint tokens = msg.value / preSaletokenPrice;

        // Adding Tokens To The Inverstor's Balance From The Founder's Balance.
        balances[msg.sender] += tokens;
        balances[founder] -= tokens; 
        deposit.transfer(msg.value); // Transfering The Value Sent To The ICO To The Deposit Address.
        preSaleCount += tokens;
        
        emit PreSale(msg.sender, msg.value, tokens);
        
        return true;
    }   

    function seedSaleSale() payable public returns(bool){ 
        seedSaleState = getSeedSaleCurrentState();
        require(seedSaleState == State.running,'seed Sale not running now');
        require(msg.value >= minInvestment && msg.value <= maxInvestment);
        require(seedSaleCount <= seedSalehardCap);
        
        raisedAmount += msg.value;
        uint tokens = msg.value / seedSaletokenPrice;

        // Adding Tokens To The Inverstor's Balance From The Founder's Balance.
        balances[msg.sender] += tokens;
        balances[founder] -= tokens; 
        deposit.transfer(msg.value); // Transfering The Value Sent To The ICO To The Deposit Address.
        seedSaleCount += tokens;
        
        emit SeedSale(msg.sender, msg.value, tokens);
        
        return true;
    } 
   
    // Burning Unsold Tokens If Required.
    function burn() public returns(bool){
        balances[founder] = 0;
        return true;        
    }    
    
}