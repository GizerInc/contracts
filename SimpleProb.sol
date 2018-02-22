contract random {
    /* Generates a random number from 0 to 100 based on the last block hash */
    function randomGen(uint seed) constant returns (uint randomNumber) {
        return(uint(sha3(block.blockhash(block.number-1), seed ))%100);
    }

    /* generates a number from 0 to 2^n based on the last n blocks */
    function multiBlockRandomGen(uint seed, uint size) constant returns (uint randomNumber) {
        uint n = 0;
        for (uint i = 0; i < size; i++){
            if (uint(sha3(block.blockhash(block.number-i-1), seed ))%2==0)
                n += 2**i;
        }
        return n;
    }
}

import "dev.oraclize.it/api.sol";

contract SimpleProb is usingOraclize {
    address owner;
    mapping (bytes32 => address) bets;

    function Lottery(){
        owner = msg.sender;
    }

    function __callback(bytes32 myid, string result) {
        if (msg.sender != oraclize_cbAddress()) throw;
        if (uint(bytes(result)[0]) - 48 > 3) bets[myid].send(2);
    }
    
    function bet(){
        if ((msg.value != 1)||(this.balance < 2)) throw;
        rollNum();
    }
    
    function rollNum() {
        bytes32 myid = oraclize_query(0, "WolframAlpha", "random number between 1 and 6");
        bets[myid] = msg.sender;
    }
    
    function kill(){
        if (msg.sender == owner) suicide(msg.sender);
    }
}
