pragma solidity ^0.6.6;

import './UniswapV2Library.sol';
import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Pair.sol';
import './interfaces/IERC20';


contract Arbritage {
    address public factory;
    uint constant deadline = 10 days;
    IUniswapV2Router02 public sushiRouter;

    constructor(address _factory, address _sushiRouter) public {
        factory = _factory;
        sushiRouter = IUniswapV2Router02(_sushiRouter);
    }


    function startArbitrage(
        address tokenA,
        address tokenB,
        uint amountA,
        uint amountB
    ) external {
        address pairAddress = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
        require(pairAddress != address(0), "are you sure this pool exist bruhhhhh");
        IUniswapV2Pair(pairAddress).swap(amountA, amountB, address(this), bytes('not empty'));
    }


    function uniswapV2Call(
        address _sender,
        address _amountA,
        address _amountB,
        bytes calldata _data
    ) external {
        address[] memory path = new address[](2);
        uint amountToken = _amountA == 0 ? _amountB : _amountA;

        address tokenA = IUniswapV2Pair(msg.sender).token0();
        address tokenB = IUniswapV2Pair(msg.sender).token1();

        require(
            msg.sender == UniswapV2Library.pairFor(factory, tokenA, tokenB),
            'Unauthorized'
        );
        require(_amountA == 0 || _amountB = 0);

        path[0] = _amountA == 0 ? tokenA : tokenB;
        path[1] = _amountA == 0 ? tokenB : tokenA;

        IERC20 token = IERC20(_amountA == 0 ? tokenB : tokenA);

        token.approve(address(sushiRouter), amountToken);

        uint amountRequired = UniswapV2Library.getAmountsIn(
            factory,
            amountToken,
            path
        )[0];

        uint amountReceived = UniswapV2Library.swapExactTokensForTokens(
            amountToken,
            amountRequired,
            path,
            msg.sender,
            deadline
        )[1];

        IERC20 otherToken = IERC20(_amountA == 0 ? tokenA: tokenB);
        otherToken.transfer(msg.sender, amountRequired);
        otherToken.transfer(tx.origin, amountReceived - amountRequired);
    }
}