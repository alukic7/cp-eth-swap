import * as dotenv from 'dotenv'
import { ethers } from 'hardhat'
dotenv.config()

/**
 * npx hardhat run scripts/deploy.ts --network sepolia \
 *   --token 0xYourERC20Address
 */
async function main() {
  // get --token CLI arg or fallback to env
  const tokenAddr =
    process.env.TOKEN || process.argv[process.argv.indexOf('--token') + 1]
  if (!ethers.isAddress(tokenAddr))
    throw new Error('Provide --token <ERC20_ADDRESS>')

  const AMM = await ethers.getContractFactory('ConstantProductAMM')
  const amm = await AMM.deploy(tokenAddr)
  await amm.waitForDeployment()

  console.log('AMM deployed to:', await amm.getAddress())
}

main().catch(e => {
  console.error(e)
  process.exitCode = 1
})
