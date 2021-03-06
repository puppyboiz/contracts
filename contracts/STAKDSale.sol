pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";

pragma solidity 0.6.12;

contract STAKDSale {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    address payable public collector =
        0x24A6578b8ccB13043f4Ef4E131e8A591E89B1b97;
    uint256 public minAmount = 0.5 ether;
    uint256 public maxAmount = 10 ether;
    uint256 public capAmount = 1000 ether;
    uint256 private constant SALE_DURATION = 3 hours;
    uint256 public bnbRaised;
    uint256 public immutable saleEnd;
    uint256 public saleStart = 1614096000; // 4 PM UTC, 23 february
    bool public saleActive = false;
    mapping(address => uint256) public userbuys;

    constructor() public {
        saleEnd = saleStart.add(SALE_DURATION);
    }

    fallback() external payable {
        buyTokens();
    }

    receive() external payable {
        buyTokens();
    }

    function canUserBuy(address _address) external view returns (bool) {
        if (userbuys[_address] < maxAmount) {
            return true;
        } else return false;
    }

    function isSaleActive() public view returns (bool) {
        if (block.timestamp >= saleStart && block.timestamp <= saleEnd) {
            return true;
        } else return false;
    }

    function secondsUntilSale() external view returns (uint256) {
        if (block.timestamp <= saleStart) {
            return saleStart.sub(block.timestamp);
        } else return 0;
    }

    function secondsUntilEnd() external view returns (uint256) {
        if (block.timestamp >= saleStart && block.timestamp <= saleEnd) {
            return saleEnd.sub(block.timestamp);
        } else return 0;
    }

    function buyTokens() public payable {
        require(msg.sender != address(0));
        require(
            msg.value >= minAmount && msg.value <= maxAmount,
            "Not correct amount"
        ); //checks amount is between 0.5 and 10 bnb
        require(isSaleActive(), "sale not active"); //checks sale active
        require(msg.value.add(bnbRaised) <= capAmount, "Cap reached!"); //checks for cap reached
        require(
            userbuys[msg.sender].add(msg.value) <= maxAmount,
            "Can't contribute more"
        ); //checks user max buy is 10 bnb
        require(block.timestamp <= saleEnd, "Sale ended");

        (bool sent, bytes memory data) = collector.call{value: msg.value}("");
        require(sent, "Failed to send Bnb");
        bnbRaised = bnbRaised.add(msg.value);
        userbuys[msg.sender] = userbuys[msg.sender].add(msg.value);
    }

    function drainBNB() external {
        //if any bnb is left in the contract
        require(msg.sender == address(collector), "nice try");
        collector.transfer(address(this).balance);
    }

    function drainTokens(address _token) external {
        //if any tokens are sent in the contract
        require(msg.sender == address(collector), "nice try");
        IBEP20 token = IBEP20(_token);
        token.safeTransfer(collector, token.balanceOf(address(this)));
    }
}
