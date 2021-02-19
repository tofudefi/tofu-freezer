pragma solidity ^0.5.0;

library SafeMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128) {
        uint128 c = a + b;
        require(c >= a, "SafeMath128: addition overflow");

        return c;
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128) {
        return sub(a, b, "SafeMath128: subtraction overflow");
    }

    function sub(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
        require(b <= a, errorMessage);
        uint128 c = a - b;

        return c;
    }

    function mul(uint128 a, uint128 b) internal pure returns (uint128) {
        // optimization
        if (a == 0) {
            return 0;
        }

        uint128 c = a * b;
        require(c / a == b, "SafeMath128: multiplication overflow");

        return c;
    }

    function div(uint128 a, uint128 b) internal pure returns (uint128) {
        return div(a, b, "SafeMath128: division by zero");
    }

    function div(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint128 c = a / b;

        return c;
    }

    function mod(uint128 a, uint128 b) internal pure returns (uint128) {
        return mod(a, b, "SafeMath128: modulo by zero");
    }

    function mod(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
