pragma solidity ^0.5.14;

import './ITRC20.sol';

interface TRC20FreezerOps {

    function token() external view returns (ITRC20);
    function freezeDuration() external view returns (uint64);

    /**
     * @dev Sets private variable for freeze duration making sanity checks beforehand.
     *
     * Can only be accessed by contract owner.
    */
    function setFreezeDuration(uint64 argFreezeDuration) external; // throws 'Forbidden', 'Too big', 'Too small'

    /**
     * @dev Withdraws APPROVED amount of serviced token from member, deposits it to this contract's address and freezes it.
    */
    function freeze(uint128 amount) external; // throws 'Withdrawal exception', 'Too much frozen for user', 'Max members reached'

    /**
     * @dev Checks if freeze is in effect and if not transfers `amount` back to member.
     * Withdraws 'all or nothing' regarding current freezed amount.
     * Returns how many funds remaining in other freezes.
    */
    function unfreeze(uint128 amount) external
        returns(uint128 remainingStakesValue); // throws 'No frozen amount', 'Freeze in effect', 'Token exception'

    /**
     * @dev Checks if freeze is in effect for all freezed funds (checks max expiry) and if not transfers `amount` back to member.
     * Withdraws 'all or nothing' regarding all freezed funds.
    */
    function unfreezeAll() external; // throws 'No frozen amount', 'Freeze in effect', 'Token exception'

    /**
     * @dev Returns records of frozen funds for member. Returns zero length array if no freezes.
     * Array elements are uint256 numbers in which 2 uint128 numbers are packed: first is frozen amount, second is expiryTimestamp.
    */
    function listFrozenRecords(address member) external view returns(uint64[] memory expiryTimestamps, uint128[] memory amounts);

    /**
     * @dev Returns total amount of frozen tokens for member. If no such funds returns 0.
    */
    function balanceOf(address member) external view returns(uint128);

    /**
     * @dev Returns expiry timestamp for member's longest freeze. If no such freezes returns 0.
    */
    function getMaxExpiry(address member) external view returns(uint64);

    event TokensFrozen(address indexed member, uint128 amount, uint64 expiryTimestamp);
    event TokensUnfrozen(address indexed member, uint128 amount);

}
