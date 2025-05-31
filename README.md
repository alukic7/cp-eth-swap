# Simple Constant‑Product ETH Swap

A simple Solidity implementation of the classic constant product **x·y = k** automated‑market‑maker (AMM).

* add / remove liquidity with **ETH/ERC‑20** pairs
* swap ETH for tokens and vice‑versa
* earn a 0.30 % fee (accrued inside the pool) as a liquidity provider

---

## ⚙️ How it works

1. **Invariant** – The pool keeps `reserveETH * reserveToken = k` after every swap.

2. **Fee** – A 0.30 % swap fee is applied via `amountIn * 997 / 1000`; the fee stays in the pool, growing *k* and rewarding LPs.

3. **LP Shares** – Liquidity providers receive proportional “shares” and can burn them later to withdraw funds plus accrued fees.

4. **Price formula** – Same as Uniswap V2:

   \$\displaystyle amountOut = \frac{amountIn·997·reserveOut}{reserveIn·1000 + amountIn·997}\$

5. **Reentrancy Guard** – OpenZeppelin’s `ReentrancyGuard` blocks nested calls.


---

## 🚀 Setup

```bash
# 1. Clone & install
git clone https://github.com/alukic7/cp-eth-swap.git
cd cp-eth-swap && npm install

# 2. Create env & compile
cp .env.example .env   # fill SEPOLIA_RPC and PRIVATE_KEY
npx hardhat compile

# 3. Deploy to Sepolia
npx hardhat run scripts/deploy.ts --network sepolia
```

Environment file (`.env`)

```ini
SEPOLIA_RPC=https://sepolia.infura.io/v3/<projectId>
PRIVATE_KEY=0xYourPrivateKey
```

---

## 💻 Helper scripts

* **`scripts/deploy.ts`** – deploy a new pool pointing to an existing ERC‑20.
* **`scripts/addLiquidity.ts`** – CLI example for providing liquidity from the same wallet.

Run them with:

```bash
npx hardhat run scripts/addLiquidity.ts --network sepolia
```

---

## 🔐 Security notes

* **No oracle / TWAP** – susceptible to price manipulation if used as a price feed.
* **No flash‑loan mitigation**.
* **Single pool** – no factory or router; every additional pair needs a new deploy.
* **Gas optimizations** kept minimal for clarity (e.g., no custom errors).

⚠️ NOTE: This code is **NOT** audited.
