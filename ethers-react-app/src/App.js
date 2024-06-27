import React, {useEffect, useState} from 'react';
import {ethers} from 'ethers';
import '@fontsource/roboto/300.css';
import '@fontsource/roboto/400.css';
import '@fontsource/roboto/500.css';
import '@fontsource/roboto/700.css';
import CssBaseline from '@mui/material/CssBaseline';
import Box from '@mui/material/Box';
import Container from '@mui/material/Container';
import Button from '@mui/material/Button';
import {TextField} from "@mui/material";
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableContainer from '@mui/material/TableContainer';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import Paper from '@mui/material/Paper';

function App() {
    const [network, setNetwork] = useState('');
    const [contract, setContract] = useState(null);
    const [provider, setProvider] = useState(null);
    const [searching, setSearching] = useState(false);
    const [transactions, setTransactions] = useState([]);
    const [ratios, setRatios] = useState([0, 0, 0])
    const [eth_addr, setAddress] = useState("")
    const [api_key, setAPI] = useState("")

    useEffect(() => {

        const initializeProvider = async () => {
            if (window.ethereum) {
                await window.ethereum.request({method: 'eth_requestAccounts'});
                const provider = new ethers.providers.Web3Provider(window.ethereum);
                setProvider(provider);
            }
        };

        initializeProvider();

        const getNetwork = async () => {
            if (provider) {
                const network = await provider.getNetwork();
                setNetwork(network.name);
            }
        };

        getNetwork();

        const deployContract = async () => {
            if (provider) {
                const signer = provider.getSigner();
                const ContractFactory = new ethers.ContractFactory(ABI, Bytecode, signer);
                const deployedContract = await ContractFactory.deploy();
                await deployedContract.deployed();
                setContract(deployedContract);
            }
        };

        deployContract();
    }, [provider]);

    const interactWithContract = async () => {
        if (contract) {
            const result = await contract.calculateTRRatio(eth_addr, api_key);
            setRatios(result)
            console.log(result);
            setSearching(true);
        }
    };

    const cancelAll = async () => {
        setSearching(false);
        setTransactions([]);
        setRatios([0, 0, 0]);
    }

    const handleAddr = (event) => {
        setAddress(event.target.value);
    }

    const handleAPI = (event) => {
        setAPI(event.target.value);
    }

    return (
        <React.Fragment>
            <CssBaseline/>
            <Container maxWidth="sm">
                <Box sx={{m: 1, width: '25ch'}}
                     autoComplete="off">
                    <h1>SainRank Algorithm</h1>
                    <TextField id="addr_input" label="Outlined" variant="outlined" value={eth_addr}
                               onChange={handleAddr}></TextField>
                    <TextField id="api_input" label="Outlined" variant="outlined" value={api_key}
                               onChange={handleAPI}>></TextField>
                    <Button onClick={interactWithContract} variant="contained">Analyse</Button>
                    <Button onClick={cancelAll} variant="contained">Clear</Button>
                </Box>
            </Container>
            {searching &&
                <Container maxWidth="sm">
                    <TableContainer component={Paper} sx={{minWidth: 650}}>
                        <Table sx={{minWidth: 650}} aria-label="transactions_table">
                            <TableHead>
                                <TableRow>
                                    <TableCell align="right">To</TableCell>
                                    <TableCell align="right">From</TableCell>
                                    <TableCell align="right">Value</TableCell>
                                </TableRow>
                            </TableHead>
                            <TableBody>
                                {transactions.map((row) => (
                                    <TableRow
                                        key={row.index}
                                        sx={{'&:last-child td, &:last-child th': {border: 0}}}
                                    >
                                        <TableCell align="right">{row.to}</TableCell>
                                        <TableCell align="right">{row.from}</TableCell>
                                        <TableCell align="right">{row.value}</TableCell>
                                    </TableRow>
                                ))}
                            </TableBody>
                        </Table>
                    </TableContainer>
                    <TableContainer component={Paper} sx={{minWidth: 650}}>
                        <Table sx={{minWidth: 650}} aria-label="ratios table">
                            <TableHead>
                                <TableRow>
                                    <TableCell align="right">Transactions Value Ratio</TableCell>
                                    <TableCell align="right">Transactions Count</TableCell>
                                    <TableCell align="right">Trust Ratio</TableCell>
                                </TableRow>
                            </TableHead>
                            <TableBody>
                                    <TableRow
                                    >
                                        <TableCell align="right">{ratios[0]}</TableCell>
                                        <TableCell align="right">{ratios[1]}</TableCell>
                                        <TableCell align="right">{ratios[2]}</TableCell>
                                    </TableRow>
                            </TableBody>
                        </Table>
                    </TableContainer>
                </Container>
            }
        </React.Fragment>
    );
}

export default App;

