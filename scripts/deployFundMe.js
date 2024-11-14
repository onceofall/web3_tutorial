// import ethers.js
const { ethers } = require("hardhat");
require("dotenv").config;

// import fundme contract
// const FundMe = require("../artifacts/contracts/FundMe.sol/FundMe.json");

async function main() {
    const fundMeFactory = await ethers.getContractFactory("FundMe");
    console.log("Deploying FundMe contract...");
    const fundMe = await fundMeFactory.deploy(10);
    await fundMe.waitForDeployment();
    console.log("FundMe deployed to:", fundMe.target);
    
    if (hre.network.config.chainId === 11155111 && process.env.ETHERSCAN_API_KEY) {
        console.log("Waiting for 5 confirmations")
        await fundMe.deploymentTransaction().wait(5) 
        await verifyFundMe(fundMe.target, [10])
    } else {
        console.log("Other network detected. Skipping verification.");
    }

        // init 2 accounts
        const [firstAccount, secondAccount] = await ethers.getSigners()
    
        // fund contract with first account
        const fundTx = await fundMe.fund({value: ethers.parseEther("0.5")})
        await fundTx.wait()
    
        console.log(`2 accounts are ${firstAccount.address} and ${secondAccount.address}`)
        
        // check balance of contract
        const balanceOfContract = await ethers.provider.getBalance(fundMe.target)
        console.log(`Balance of the contract is ${balanceOfContract}`)
    
        // fund contract with second account
        const fundTxWithSecondAccount = await fundMe.connect(secondAccount).fund({value: ethers.parseEther("0.5")})
        await fundTxWithSecondAccount.wait()
    
        // check balance of contract
        const balanceOfContractAfterSecondFund = await ethers.provider.getBalance(fundMe.target)
        console.log(`Balance of the contract is ${balanceOfContractAfterSecondFund}`)
    
        // check mapping 
        const firstAccountbalanceInFundMe = await fundMe.fundersToAmount(firstAccount.address)
        const secondAccountbalanceInFundMe = await fundMe.fundersToAmount(secondAccount.address)
        console.log(`Balance of first account ${firstAccount.address} is ${firstAccountbalanceInFundMe}`)
        console.log(`Balance of second account ${secondAccount.address} is ${secondAccountbalanceInFundMe}`)
}

async function verifyFundMe(fundMeAddr, args) {
    await hre.run("verify:verify", {
        address: fundMeAddr,
        constructorArguments: args,
      });
}

main().then().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});