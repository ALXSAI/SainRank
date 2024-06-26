# SainRank
SainRank is a contract allowing for anonymous analysis of Etherium Wallets.
The analysis is based on the number of transactions, the value of those transactions as well as the direction.
The algorithm conducts its analysis recursively, as such the people trading with the wallet also contribute to the final ratio.
By default the depth is 5 which can take several hours to fully calculate, at each depth the weight of the data decreases by 1.
With wallets closest to the target being weighted by 5 and those furthest by 1(at default depth of 5).


## Variables
- oracle : node id of the responsible chainlink node
- jobId : job id for the task requested
- fee : fee calculated according to the chainlink job 
- totalIn : total value of all incoming transactions
- totalOut : total value of all outgoing transactions
- inCount : number of incoming transactions
- outCount : number of outgoing transactions
- ratio : in / out value ratio
- countir : in / out transactions number ratio
- owner : contract owner
- others : list of all wallets visited on the current run
- api_link : link hosting the etherscan API
- tr_task_url_1 : first half of the etherscan task link
- tr_task_url_2 : secont half of the etherscan task link
- transactions : list of all transactions currently loaded for the address


## TR Struct
TR struct is a simplified version of the etherscan json token. It contains 3 variables:
- From: where the transaction originated from
- To : who recieved the transaction
- Value: total value of the transaction

The TR struct is parsed from the output given by the Etherscan API


## Constructor
constructor initiates the chainlink job and token


## stringToUint
Takes a string with no whitespace, first the string is converted to bytes.
The bytes then are parsed as uint8, if they are a floating point uint they are multiplied to become a uint.
- Input: string
- Output: uint


## _stringReplace
Takes a string, index and character. Replaces the strings character at that location with the given one.
This is done by creating a new string and replacing the bytes at the location, then returning the new string
- Input: string: _string, uint256: _pos, string: _letter
- Output: _string


## bytes32ToString
Transcribes a bytes32 object to a string object.
- Input: bytes32: _bytes32
- Output: _string


## requestTransactionData
Creates a chainlink API request, builds the http request string for chainlink to invoke etherscan API
Modifies all recieved ints and floats to fit the uint256 format of solidity.
Upon request of the job invokes the fulfill function
- Input: string: _eth_addr, string: api_key
- Output: bytes32: _requestID
- Invokes: fulfill


## fulfill
Recieves the chainlink request, parses the data into string.
Afterwards iterates over the string, splits it according to results, then individual transactions, then by individual rows.
Parses through the rows and transcribes "to","from","value" lines into a new TR object and pushes it to the transactions array.
- Input: bytes32: _requestId, bytes32: _tr_data


## calculateTRRatio
Start point of the recursive analysis. Invokes the requestTransactionData function.
Calculates the number of and value of transactions and modifies them by weight. 
Calls the recursive auxiliary function with depth 5 for each direct neighbour.
Keeps track of all visited wallets through the others list
- Input: string: _eth_addr, string: api_key
- Output: uint: ratio, uint: count, TR[]: transactions

## calculateTRRatio
Auxiliary function for the recoursive analysis. recieves the current depth. 
Analyzes the transactions for the current wallet address of the recoursion.
Makes sure to not visit douplicate wallet addresses by checking them against the highest weighted entry of the wallet.
After calculation the next levels are calculated, when the result is recieved it is passed up.
- Input: string: others[i], uint: count, string: api_key
- Output: uint: ratio, uint: count