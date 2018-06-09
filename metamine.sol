pragma solidity ^0.4.0;

// event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);
// event Transfer(address indexed _from, address indexed _to, uint256 _value);
// event Approval(address indexed _owner, address indexed _spender, uint256 _value);

contract Metamine {
    
    uint256 public constant MAX_TARGET = 2**256 - 1;
    uint256 public constant totalSupply = 200000000; 
    uint256 public constant maxTxionsPerBlock = 3;
    uint256 private rewardPerBlock;
    uint256 private currentTarget;
    uint256 private mintedSupply;
    bytes32 private batchHash;
    bytes32[] private transferBatch; // this is our "block" data
    struct pendingTransfer {
        uint256 amount;
        address recipient;
    }
    pendingTransfer[] private pendingTransfers;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) public allowed;
    
    modifier blockNotFull {
        require(transferBatch.length < maxTxionsPerBlock);
        _;
    }
    
    constructor() public {
        // Set the target to something
        // incredibly easy to mine
        currentTarget = MAX_TARGET;
        rewardPerBlock = 50; // 50 new tokens per block
        mintedSupply = rewardPerBlock;
        balances[msg.sender] = rewardPerBlock;
    }
    
    function transfer(address _to, uint256 _value) public blockNotFull {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        transferBatch.push(keccak256(msg.data));
        pendingTransfers.push(pendingTransfer(_value, _to));
        batchHash = sha256(transferBatch);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public blockNotFull {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_from] -= _value;
        transferBatch.push(keccak256(msg.data));
        pendingTransfers.push(pendingTransfer(_value, _to));
        if (allowance < MAX_TARGET) { // use MAX_TARGET as max uint256
            allowed[_from][msg.sender] -= _value;
        }
        batchHash = sha256(transferBatch);
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public {
        allowed[msg.sender][_spender] = _value;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function getMiningReward() public view returns (uint256) {
        return rewardPerBlock;
    }
    
    function getBlockData() public view returns (bytes32) {
        return batchHash;
    }
    
    function getMiningDifficulty() public view returns (uint256) {
        return MAX_TARGET / currentTarget;
    }
    
    function getMiningTarget() public view returns (uint256) {
        return currentTarget;
    }
    
    function mine(uint256 nonce) public {
        // hash with nonce
        bytes32 blockHash = sha256(nonce, batchHash);
        // if this satisfies the difficulty, proceed
        require(blockHash < bytes32(currentTarget));
        // Fulfill pending transfers
        for(uint i = 0; i < pendingTransfers.length; i++) {
            balances[pendingTransfers[i].recipient] += pendingTransfers[i].amount;
        }
        // empty pending transfers
        delete pendingTransfers;
        // empty "block"/batch
        delete transferBatch;
        // reward miner
        mintedSupply += rewardPerBlock;
        balances[msg.sender] += rewardPerBlock;
    }
}
