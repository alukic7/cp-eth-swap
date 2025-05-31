// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title ConstantProductAMM
 * @notice Minimal ETH ↔️ ERC-20 pool (x·y = k). 0.30 % fee.
 */
 
contract ConstantProductAMM is ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20  public immutable token;
    uint256 public reserveETH;
    uint256 public reserveToken;

    uint256 public constant FEE_NUM = 997;
    uint256 public constant FEE_DEN = 1000;

    uint256 public totalShares;
    mapping(address => uint256) public shares;

    event LiquidityAdded(address indexed provider, uint256 eth, uint256 token, uint256 shares);
    event LiquidityRemoved(address indexed provider, uint256 eth, uint256 token, uint256 shares);
    event Swapped(address indexed trader, uint256 inETH, uint256 inTok, uint256 outETH, uint256 outTok);

    constructor(IERC20 _token) {
        token = _token;
    }

    function addLiquidity(uint256 minToken, uint256 deadline)
        external
        payable
        nonReentrant
    {
        require(block.timestamp <= deadline, "EXPIRED");
        require(msg.value > 0, "ZERO_ETH");

        uint256 tokenAmt;
        if (reserveETH == 0 && reserveToken == 0) {
            tokenAmt = minToken;               
        } else {
            tokenAmt = (msg.value * reserveToken) / reserveETH;
            require(tokenAmt >= minToken, "SLIPPAGE_TOKEN");
        }
        token.safeTransferFrom(msg.sender, address(this), tokenAmt);

        uint256 minted = (totalShares == 0)
            ? msg.value
            : (msg.value * totalShares) / reserveETH;

        require(minted > 0, "ZERO_SHARES");
        shares[msg.sender] += minted;
        totalShares += minted;

        reserveETH   += msg.value;
        reserveToken += tokenAmt;

        emit LiquidityAdded(msg.sender, msg.value, tokenAmt, minted);
    }

    function removeLiquidity(
        uint256 shareAmt,
        uint256 minETH,
        uint256 minTok,
        uint256 deadline
    ) external nonReentrant {
        require(block.timestamp <= deadline, "EXPIRED");
        require(shareAmt > 0 && shareAmt <= shares[msg.sender], "BAD_SHARES");

        uint256 ethOut   = (shareAmt * reserveETH)   / totalShares;
        uint256 tokenOut = (shareAmt * reserveToken) / totalShares;
        require(ethOut >= minETH && tokenOut >= minTok, "SLIPPAGE");

        shares[msg.sender] -= shareAmt;
        totalShares        -= shareAmt;
        reserveETH         -= ethOut;
        reserveToken       -= tokenOut;

        (bool ok, ) = msg.sender.call{value: ethOut}("");
        require(ok, "ETH_FAIL");
        token.safeTransfer(msg.sender, tokenOut);

        emit LiquidityRemoved(msg.sender, ethOut, tokenOut, shareAmt);
    }

    function swapExactETHForTokens(uint256 minTok, uint256 deadline)
        external
        payable
        nonReentrant
    {
        require(block.timestamp <= deadline, "EXPIRED");
        require(msg.value > 0, "ZERO_IN");

        uint256 tokOut = _getOut(msg.value, reserveETH, reserveToken);
        require(tokOut >= minTok, "SLIPPAGE");

        reserveETH   += msg.value;
        reserveToken -= tokOut;

        token.safeTransfer(msg.sender, tokOut);
        emit Swapped(msg.sender, msg.value, 0, 0, tokOut);
    }

    function swapExactTokensForETH(uint256 tokIn, uint256 minEth, uint256 deadline)
        external
        nonReentrant
    {
        require(block.timestamp <= deadline, "EXPIRED");
        require(tokIn > 0, "ZERO_IN");

        token.safeTransferFrom(msg.sender, address(this), tokIn);
        uint256 ethOut = _getOut(tokIn, reserveToken, reserveETH);
        require(ethOut >= minEth, "SLIPPAGE");

        reserveToken += tokIn;
        reserveETH   -= ethOut;

        (bool ok, ) = msg.sender.call{value: ethOut}("");
        require(ok, "ETH_FAIL");
        emit Swapped(msg.sender, 0, tokIn, ethOut, 0);
    }

    function _getOut(uint256 dx, uint256 xRes, uint256 yRes)
        private
        pure
        returns (uint256)
    {
        uint256 dxFee = dx * FEE_NUM;
        return (dxFee * yRes) / (xRes * FEE_DEN + dxFee);
    }

    function getPrice() external view returns (uint256) {
        return reserveToken == 0 ? 0 : (reserveETH * 1e18) / reserveToken;
    }

    receive() external payable {}
}
