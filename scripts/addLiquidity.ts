import * as dotenv from 'dotenv'
import { ethers } from 'hardhat'
dotenv.config()

async function main() {
  const [signer] = await ethers.getSigners()

  const ammAddr = process.env.AMM!
  const tokenAddr = process.env.TOKEN! // same token you passed at deploy
  const tokenAmt = ethers.parseUnits('100', 18) // amount in tokens
  const ethAmt = ethers.parseEther('0.2') // amount in ETH

  if (!ammAddr || !tokenAddr) throw new Error('Set AMM and TOKEN env vars')

  const token = await ethers.getContractAt('IERC20', tokenAddr)
  await token.connect(signer).approve(ammAddr, tokenAmt)

  const amm = await ethers.getContractAt('ConstantProductAMM', ammAddr)
  const deadline = Math.floor(Date.now() / 1000) + 60 // 1 min

  const tx = await amm.addLiquidity(tokenAmt, deadline, { value: ethAmt })
  console.log('Sent addLiquidity tx:', tx.hash)
  await tx.wait()
  console.log('Liquidity added.')
}

main().catch(e => {
  console.error(e)
  process.exitCode = 1
})
