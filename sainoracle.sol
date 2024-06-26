// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "github.com/Arachnid/solidity-stringutils/strings.sol";
import "0x97044531D0fD5B84438499A49629488105Dc58e6" as bl;

contract sainoracle is ChainlinkClient{
    using Chainlink for Chainlink.Request;
    using strings for *;

    bl.Blacklist blist = new blacklist();
    
    struct TR{
        string from;
        string to;
        uint value;
    }

    uint256 public volume;
    
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    // all wallets already visited by the algorithm
    string[] visited;

    // These variables are used for processing recursive data while lowering the amount of variables
    uint totalIn =0;
    uint totalOut =0;
    uint inCount = 0;
    uint outCount = 0;
    uint trust = 0;
    uint ratio;
    uint countir;

    address public owner;
    string private api_link = "https://api.etherscan.io/api";
    string private tr_task_url_1 = "https://api.etherscan.io/api?module=account&action=txlist&address=";
    string private tr_task_url_2 = "&startblock=0&endblock=99999999&page=1&offset=10&sort=asc&apikey=";
          
    // storage for the transaction data, needs to be refreshed as the contract can only store one wallets data at a time      
    TR[] private transactions;

    constructor (){
        owner = msg.sender;

        // we set up the chainlink api token as well as a job on the node that will handle our requests
        _setPublicChainlinkToken();
        oracle = 0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD;
        jobId = "7d80a6386ef543a3abb52817f6707e3";
        fee = 0.1 * 10 ** 18;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    // Utility function to parse a uint of any size from a string
    function stringToUint(string memory s) public pure returns (uint) {
        bytes memory b = bytes(s);
        uint result = 0;
        // since uint8 and bytes8 are the same functionally we can expliitly cast to uint8 and then to any other uint
        for (uint i = 0; i < b.length; i++) { 
            if (uint8(b[i]) >= 48 && uint8(b[i]) <= 57) {
                result = result * 10 + (uint(uint8(b[i])) - 48); 
            }
        }
        return result;
    }   

    // Utility function to replace a certain letter at a certain index of a string
     function _stringReplace(string memory _string, uint256 _pos, string memory _letter) internal pure returns (string memory) {
        bytes memory _stringBytes = bytes(_string);
        bytes memory result = new bytes(_stringBytes.length);

        for(uint i = 0; i < _stringBytes.length; i++) {
            result[i] = _stringBytes[i];
            if(i==_pos)
                result[i]=bytes(_letter)[0];
        }
        return  string(result);
    } 

    // Utility function that parses a bytes32 object and provides a string from it
    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    // Main data request function that registeds a HTTP Get request with chainlink who later passes it on to etherscan\
    function requestTransactionData(string memory eth_addr, string calldata api_key) public returns(bytes32 _requestID){
        Chainlink.Request memory req = _buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );


        string memory transaction_task_url = string.concat(
            string.concat(
                string.concat(
                    tr_task_url_1, eth_addr),
                    tr_task_url_2),
                    api_key);

        req._add(
            "get",
            transaction_task_url
        );

        req._add("path", "result");
        int256 timesAmount = 10 ** 18;
        req._addInt("times", timesAmount);

        return _sendChainlinkRequest(req, fee);
    }     

    function fulfill(
        bytes32 _requestId,
        bytes32 _tr_data
    ) public recordChainlinkFulfillment(_requestId){
        strings.slice memory prelim_tr_data =  bytes32ToString(_tr_data).toSlice();
        strings.slice memory delim = "}, {".toSlice();
        strings.slice memory delim2 = ",".toSlice();
        strings.slice memory delim3 = ";".toSlice();
        uint counter = prelim_tr_data.count(delim) + 1;
        TR[] memory _transactions = new TR[](counter); 
        for(uint i = 0; i < counter; i++) {
            string memory tempo1 = prelim_tr_data.split(delim).toString();
            uint counter2 = tempo1.toSlice().count(delim2) + 1;
            for(uint j = 0; j < counter2; j++){
                strings.slice memory tempo = tempo1.toSlice().split(delim2);
                strings.slice memory str1 = tempo.split(delim3);
                string memory str2 = tempo.split(delim3).toString();
                if(str1.contains("to".toSlice())){
                    str2 = _stringReplace(str2,0,"");
                    str2 = _stringReplace(str2,0,"");
                    uint countersrt = str2.toSlice().len();
                    str2 = _stringReplace(str2,countersrt-1,"");
                    _transactions[i].to = str2;
                }
                if(str1.contains("from".toSlice())){
                    str2 = _stringReplace(str2,0,"");
                    str2 = _stringReplace(str2,0,"");
                    uint countersrt = str2.toSlice().len();
                    str2 = _stringReplace(str2,countersrt-1,"");
                    _transactions[i].to = str2;
                }
                if(str1.contains("value".toSlice())){
                    str2 = _stringReplace(str2,0,"");
                    str2 = _stringReplace(str2,0,"");
                    uint countersrt = str2.toSlice().len();
                    str2 = _stringReplace(str2,countersrt-1,"");
                    _transactions[i].value = stringToUint(str2);
                }
            }
            
        }

        for(uint i = 0; i < _transactions.length; i++){
            transactions.push(_transactions[i]);
        }
    }  

    function calculateTRRatio(string calldata eth_addr, string calldata api_key) public returns(uint256, uint256, uint256, TR[]){
        requestTransactionData(eth_addr, api_key);
        string[] memory others = new string[](transactions.length);
        for(uint i = 0; i < transactions.length; i++){
            if(transactions[i].to.toSlice().equals(eth_addr.toSlice())){
                inCount++;
                totalIn += transactions[i].value;
                others[i] = transactions[i].from;
            }else{
                outCount++;
                totalOut += transactions[i].value;
                others[i] = transactions[i].to;
            }
        }

        visited.push(eth_addr);

        uint in_out_ratio = 5*totalIn / totalOut;
        uint in_out_count = 5*inCount / outCount;
        uint trust = 0;

        if(blist.isBlacklisted(eth_addr)){
            trust += in_out_count*in_out_ratio / 90;
        }else{
            trust += in_out_ratio*in_out_count;
        }

        for(uint i = 0; i < others.length; i++){
            bool tempo = true;
            for(uint j = 0; j < visited.length; j++){
                if(visited[j].toSlice().equals(others[i].toSlice()) && tempo)
                    tempo = false;
            }
            if (tempo){
                (ratio, countir, trustr) = calculateRecursiveTRRatios(others[i], 5,api_key);
                in_out_ratio += ratio/others.length;
                in_out_count += countir/others.length;
                trustr += trust/others.length;
            }
        }

        visited = [""];

        return (in_out_ratio, in_out_count, trustr, transactions);
    }

    function calculateRecursiveTRRatios( string memory eth_addr, uint count, string calldata api_key) private returns (uint, uint){
        if(count == 0){
            return(0,0);
        }
        
        totalIn =0;
        totalOut =0;
        inCount = 0;
        outCount = 0;
        requestTransactionData(eth_addr, api_key);
        string[] memory others = new string[](transactions.length);
        for(uint i = 0; i < transactions.length; i++){
            if(transactions[i].to.toSlice().equals(eth_addr.toSlice())){
                inCount++;
                totalIn += transactions[i].value;
                others[i] = transactions[i].from;
            }else{
                outCount++;
                totalOut += transactions[i].value;
                others[i] = transactions[i].to;
            }
        }

        visited.push(eth_addr);

        uint in_out_ratio = count*totalIn / totalOut;
        uint in_out_count = count*inCount / outCount;
        uint trustr = 0;

        if(blist.isBlacklisted(eth_addr)){
            trustr += in_out_count*in_out_ratio/(count * 15);
        }else{
            trustr += in_out_ratio*in_out_count;
        }

        for(uint i = 0; i < others.length; i++){
            bool tempo = true;
            for(uint j = 0; j < visited.length; j++){
                if(visited[j].toSlice().equals(others[i].toSlice()) && tempo)
                    tempo = false;
            }
            if (tempo){
                (ratio, countir, trust) = calculateRecursiveTRRatios(others[i], count--,api_key);
                in_out_ratio += ratio/others.length;
                in_out_count += countir/others.length;
                trustr += trust/others.length;
            }
        }
        return (in_out_ratio, in_out_count, trustr);
    }


}

