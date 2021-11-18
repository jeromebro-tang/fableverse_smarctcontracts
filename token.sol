// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";   
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol";    
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";     
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol";  
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

contract XXX is ERC20, Ownable {
    using SafeMath for uint256;
    //TBD
    uint256 public maxSupply = ;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    uint256 public whiteCount =0;
    uint256 public frozenCount =0;

    // tax
    //TBD
    uint256 public buyTransferFee = ;
    uint256 public sellTransferFee = ;
    uint256 public whaleTax = ;
    uint256 public whaleThreshold = ;  

    //wallet address to be create
    address public taxAddress = ;
    address public rewardAddress = ;
    address public devAddress = ;
    address public marketingAddress = ;
    address public reserveAddress = ; 
    
    //main
    address public pancakeAddress = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    address[] public whiteAddressList;
    address[] public frozenAddressList;
    
    constructor() public ERC20("XXX", "XXX"){ // TICKER

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        super._approve(address(this), address(uniswapV2Router), ~uint256(0));
        super._mint(_msgSender(), maxSupply);
        
        //Transfers to each wallet according to tokenomics
        //percentage to be fill according to Tokenomics
        super.transfer(marketingAddress, maxSupply.mul(0).div(100)); 
        super.transfer(rewardAddress, maxSupply.mul(0).div(100)); 
        super.transfer(devAddress, maxSupply.mul(0).div(100));
        super.transfer(reserveAddress, maxSupply.mul(0).div(100));        
    }
    
    /// @dev overrides transfer for tokenomics
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    /// @dev overrides transferFrom for tokenomics
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool){
        _transfer(sender, recipient, amount);
        return true;
    }
        
    /// @notice Creates _amount token to `_to`. Must only be called by the owner (MasterChef).
    function setTaxAddress(address _taxAddress) external onlyOwner {
        taxAddress = _taxAddress;
    }
    

    function updateTxnFeeBuy(uint256 _buyTransferFee) external onlyOwner {
        buyTransferFee = _buyTransferFee;
    }
    
    function updateTxnFeeSell(uint256 _sellTransferFee) external onlyOwner {
        sellTransferFee = _sellTransferFee;
    }
    
    function updateWhalethreshold(uint256 _whaleThreshold) external onlyOwner {
        whaleThreshold = _whaleThreshold;
    }
    
    function updateWhaletax(uint256 _whaleTax) external onlyOwner {
        whaleTax = _whaleTax;
    }
    
    function addToWhiteList(address taxFreeAddress) external onlyOwner{
        whiteAddressList.push(taxFreeAddress);
        whiteCount = whiteCount + 1;
    }
    
    function addToFrozenList(address fullTaxAddress) external onlyOwner{
        whiteAddressList.push(fullTaxAddress);
        frozenCount = frozenCount + 1;
    }

    function isWhitelisted(address tocheck) internal view returns(bool){
        bool checker = false;
       
        for (uint i=0; i<whiteAddressList.length; i++) {
            if (tocheck == whiteAddressList[i]){
                checker = true;
            }  
        }
        return (checker);
    }

    function isFrozen(address tocheck) public view returns(bool){
        bool checker = false;
        
        for (uint i=0; i<frozenAddressList.length; i++) {
            if (tocheck == frozenAddressList[i]){
                checker = true;
            }
        }
        return checker;
        
    }

    function removeFromFrozen(address toRemove) external onlyOwner{
        for(uint i = 0; i<frozenAddressList.length; i++){
            if (toRemove == frozenAddressList[i]){
                uint256 addressIndex = i;
                delete frozenAddressList[addressIndex];
            }
        }
    }
    
    function removeFromWhite(address toRemove) external onlyOwner{
        for(uint i = 0; i<whiteAddressList.length; i++){
            if (toRemove == whiteAddressList[i]){
                uint256 addressIndex = i;
                delete whiteAddressList[addressIndex];
            }
        }
    }

    /// @dev overrides transfer for tokenomics
    function _transfer( address sender, address recipient, uint256 amount ) internal virtual override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!isFrozen(sender), "The address is frozen");
        if(
            (sender != taxAddress) && (sender != owner()) && 
            (recipient != taxAddress) && (recipient != owner()) && (!isWhitelisted(sender))
        ){
            if(sender == pancakeAddress) { // Sender is not uniswaprouter = buy
                uint256 _fee = amount.mul(buyTransferFee).div(100);
                super._transfer(sender, taxAddress, _fee); 
                amount = amount.sub(_fee);
            } else{

                    if(amount > whaleThreshold){
                        uint256 _fee = amount.mul(whaleTax).div(100);
                        super._transfer(sender, taxAddress, _fee); 
                        amount = amount.sub(_fee);
                    } else{
                        uint256 _fee = amount.mul(sellTransferFee).div(100);
                        super._transfer(sender, taxAddress, _fee); 
                        amount = amount.sub(_fee);
                    
                } 
            }
        }
        super._transfer(sender, recipient, amount);
    }

    
    
}