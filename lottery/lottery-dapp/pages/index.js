import { useState, useEffect } from 'react'
import Head from 'next/head'
import { ethers} from 'ethers'
import styles from '@/styles/Home.module.css'
import 'bulma/css/bulma.css'

export default function Home() {
  const [provider, setProvider] = useState()
  const [address, setAddress] = useState()
  const [lcContract, setLcContract] = useState()
  const [lotteryPot, setLotteryPot] = useState()
  const [lotteryPlayers, setPlayers] = useState()
  const [lotteryHistory, setLotteryHistory] = useState([])
  const [lotteryId, setlotteryId] = useState()
  const [error, setError] = useState('')
  const [successMsg, setSuccessMsg] = useState('')

  useEffect(() => {
    if(lcContract){
      updateState();
    }
  }, [lcContract]);

  const useEffect = () => {
    if (lcContract) {
      getPot();
     getPlayers();
     getLotteryId();
    }

  //Get a default provider
  const provider = ethers.getDefaultProvider()
  setProvider(provider)

  // Get a signer for the connected account
  const signer = provider.getSigner()
  setAddress(signer.getAddress())

  // Contract instance with the lottery contract address and ABI
  const lcContract = new ethers.Contract(
    "0x1057cC48F7C7DfE7542B7697e3C73e71557068A8",[
      'function createGreeting(string memory _greeting) public',
      'function greet() public view returns (string memory)',
        'unction lastGreeting() public view returns (string memory)',
        'function lastGreetingFrom(address _from) public view returns (string memory)',
    ],
    signer
  )
  setLcContract(lcContract)
}

  const getPot = async () => {
    //contract.balance to get the balance of the contract
    const pot = await lcContract.balance
    // ethers.utilis.formatEther() to convert wei to ether
    setLotteryPot(ethers.utils.formatEther(pot))
  }

  const getPlayers = async () => {
  //contract.functions to call the contract methods
    const players = await lcContract.functions.getPlayers()
    setPlayers(players)
  }

  const getHistory = async (id) => {
    setLotteryHistory([])
    for (let i = parseInt(id); i > 0; i--) {
    //contract.functions to call the contract methods
      const winnerAddress = await lcContract.functions.lotteryHistory(i)
      const historyObj = {}
      historyObj.id = i
      historyObj.address = winnerAddress
      setLotteryHistory(lotteryHistory => [...lotteryHistory, historyObj])
    }
  }

  const getLotteryId = async () => {
    //contract.functions to call the contract methods
    const lotteryId = await lcContract.functions.lotteryId()
    setLotteryId(lotteryId)
    await getHistory(lotteryId)
  }

  const enterLotteryHandler = async () => {
    setError('')
    setSuccessMsg('')
    try {
      await lcContract.functions.enter({
        value: ethers.utilis.parseEther('0.015'),
        gasLimit: 300000,
        gasPrice: null
      })
      updateState()
    } catch (err) {
      setError(err.message)
    }
  }

  const selectWinnerHandler = async () => {
    setError('')
    setSuccessMsg('')
    console.log(`address from select winner :: ${address}`)
    try {
      await lcContract.functions.pickWinner({
        from: address,
        gas: 300000,
        gasPrice: null
      })
    } catch (err) {
      setError(err.message)
    }
  }

  const payWinnerHandler = async () => {
    setError('')
    setSuccessMsg('')
    try {
      await lcContract.functions.payWinner({
        gasLimit: 300000,
        gasPrice: null
      })

      console.log(`lottery id :: ${lotteryId}`)
      const winnerAddress = await lcContract.functions.lotteryHistory(lotteryId)
      setSuccessMsg(`The winner is ${winnerAddress}`)
      updateState()
    } catch (err) {
      setError(err.message)
    }
  }


  const connectWalletHandler = async () => {
    setError('')
    setSuccessMsg('')
    // Check if Metamask is installed
    if (typeof window !== 'undefined' && typeof window.ethereum !== 'undefined') {
      try {
        // Request wallet connection
        await window.ethereum.request({ method: 'eth_requestAccounts' })
        // Provider instance & set to state 
        const provider = ethers.getDefaultProvider()
        // Provider instance in react state
        setProvider(provider)
        //get signer for the connected account
        const signer = provider.getSigner()
        // set account 1 to react state
        setAddress(signer.getAddress())

        //Create local contract copy
        const lc = lotteryContract(web3)
        setLcContract(lc)

       // Create a contract instance with the lottery contract address and abi
       const lcContract = new ethers.Contract(
        "0xf22063aC68185A967eb71a2f5b877336b64bF9E1",
        [
          "function createGreeting(string memory _greeting) public",
          "function greet() public view returns (string memory)",
          "function lastGreeting() public view returns (string memory)",
          "function lastGreetingFrom(address _from) public view returns (string memory)",
        ],
        signer
      )
      setLcContract(lcContract)

      // Listen for events from the contract
      lcContract.on("LotteryEntered", (player, amount) => {
        console.log(`${player} entered the lottery with ${amount} wei`)
      })

      lcContract.on("LotteryWinner", (winner, amount) => {
        console.log(`${winner} won the lottery with ${amount} wei`)
      })

    } catch (err) {
      setError(err.message)
    }
  } else {
    //Metamask is not installed
    console.log("Please install Metamask")
  }
  }


  return (
    <div>
      <Head>
        <title>BlockchainUNN Lottery dapp</title>
        <meta name="description" content="Lottery dapp" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <main className={styles.main}>
        <nav className="navbar mt-4 mb-4">
          <div className="container">
            <div className="navbar-brand">
              <h1>BUNN Lottery</h1>
            </div>
            <div className="navbar-end">
              <button onClick={connectWalletHandler} className="button is-link">Connect Wallet</button>
            </div>
          </div>
        </nav>
        <div className="container">
          <section className="mt-5">
            <div className="columns">
              <div className="column is-two-thirds">
                <section className="mt-5">
                  <p>Begin the lottery by sending 0.01 Ether</p>
                  <button onClick={enterLotteryHandler} className="button is-link is-large is-light mt-3">Play now</button>
                </section>
                <section className="mt-6">
                  <p><b>Admin only:</b> Select winner</p>
                  <button onClick={selectWinnerHandler} className="button is-primary is-large is-light mt-3">Select Winner</button>
                </section>
                <section className="mt-6">
                  <p><b>Admin only:</b> Pay winner</p>
                  <button onClick={payWinnerHandler} className="button is-success is-large is-light mt-3">Pay Winner</button>
                </section>
                <section>
                  <div className="container has-text-danger mt-6">
                    <p>{error}</p>
                  </div>
                </section>
                <section>
                  <div className="container has-text-success mt-6">
                    <p>{successMsg}</p>
                  </div>
                </section>
              </div>
              <div className={`${styles.lotteryinfo} column is-one-third`}>
                <section className="mt-5">
                  <div className="card">
                    <div className="card-content">
                      <div className="content">
                        <h2>Lottery History</h2>
                        {
                          (lotteryHistory && lotteryHistory.length > 0) && lotteryHistory.map(item => {
                            if (lotteryId != item.id) {
                              return <div className="history-entry mt-3" key={item.id}>
                                <div>Lottery #{item.id} winner:</div>
                                <div>
                                  <a href={`https://etherscan.io/address/${item.address}`} target="_blank">
                                    {item.address}
                                  </a>
                                </div>
                              </div>
                            }
                          })
                        }
                      </div>
                    </div>
                  </div>
                </section>
                <section className="mt-5">
                  <div className="card">
                    <div className="card-content">
                      <div className="content">
                        <h2>Players ({lotteryPlayers})</h2>
                        <ul className="ml-0">
                          {
                            (lotteryPlayers && lotteryPlayers.length > 0) && lotteryPlayers.map((player, index) => {
                              return <li key={`${player}-${index}`}>
                                <a href={`https://etherscan.io/address/${player}`} target="_blank">
                                  {player}
                                </a>
                              </li>
                            })
                          }
                        </ul>
                      </div>
                    </div>
                  </div>
                </section>
                <section className="mt-5">
                  <div className="card">
                    <div className="card-content">
                      <div className="content">
                        <h2>Pot</h2>
                        <p>{lotteryPot} Ether</p>
                      </div>
                    </div>
                  </div>
                </section>
              </div>
            </div>
          </section>
        </div>
      </main>

      <footer className={styles.footer}>
        <p>&copy; 2023 BlockchainUNN Lottery favxlaw </p>
      </footer>
    </div>
  )
}
