pragma solidity ^0.5.14;

import './ITRC20.sol';
import './SafeMath128.sol';
import './TRC20FreezerOps.sol';

contract TofuFreezer is TRC20FreezerOps {
    using SafeMath128 for uint128;

    uint32 constant public MAX_DURATION = 365 days;
    uint8 constant public MAX_FREEZES_PER_USER = 255;

    address private owner;

    ITRC20 public token;
    uint64 public freezeDuration;

    mapping (address => FreezesRecord) private freezeLedger;

    struct FreezeLog {
        uint128 amount;
        uint64 expiryTimestamp;
    }

    struct FreezesRecord {
        uint64 maxExpiryTs;
        uint128 totalAmount;
        FreezeLog[] logs;
    }

    constructor(ITRC20 argToken, uint64 argFreezeDuration) public {
        require(argFreezeDuration > 0 && argFreezeDuration <= MAX_DURATION,
            "Stake duration out of bounds: (0, MAX_DURATION]");
        token = argToken;
        freezeDuration = argFreezeDuration;
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner,
            "Forbidden");
        _;
    }

    function setFreezeDuration(uint64 argFreezeDuration) public onlyOwner {
        require(argFreezeDuration > 0,
            "Too small: 0");
        require(argFreezeDuration < MAX_DURATION,
            "Too big: MAX_DURATION");
        freezeDuration = argFreezeDuration;
    }

    function freeze(uint128 amount) public {
        address member = msg.sender;
        FreezesRecord storage record = freezeLedger[member];
        FreezeLog[] storage logs = record.logs;
        require(logs.length < MAX_FREEZES_PER_USER,
            "Too much frozen for user: MAX_FREEZES_PER_USER");

        bool success = token.transferFrom(member, address(this), amount);
        require(success,
            "Withdrawal exception");

        uint64 expiry = freezeDuration + uint64(block.timestamp);

        logs.push(FreezeLog(amount, expiry));

        record.totalAmount += amount;
        if (record.maxExpiryTs < expiry) {
            record.maxExpiryTs = expiry;
        }
        //freezeLedger[client] = record; // try remove this line

        emit TokensFrozen(member, amount, expiry);
    }

    function unfreeze(uint128 amount) public returns(uint128 remainingFrozenValue) {
        address member = msg.sender;
        FreezesRecord storage rec = freezeLedger[member];
        FreezeLog[] storage logs = rec.logs;
        uint64 size = uint64(logs.length);
        require(size > 0,
            "No frozen amount");

        uint64 nowTs = uint64(block.timestamp);
        bool notFound = true;
        for (uint64 i = 0; i < size; i++) {
            FreezeLog storage l = logs[i];

            if (l.expiryTimestamp <= nowTs && l.amount == amount) {
                // these expired so we can return them
                uint64 s = size - 1;
                if (i < s) {
                    logs[i] = logs[s];
                }
                logs.pop();

                notFound = false;
                break;
            }
        }

        if (notFound) {
            revert("Freeze in effect");
        }

        if (size - 1 /*we removed exactly one element*/ == 0) {
            // array is empty hence no frozen funds left therefore let's 'remove' it from ledger (i.e. nullify everything)
            removeRecord(rec);
            remainingFrozenValue = 0;
        }
        else {
            rec.totalAmount -= amount;
            remainingFrozenValue = rec.totalAmount;
        }

        withdraw(member, amount);
    }

    function unfreezeAll() public {
        address member = msg.sender;
        FreezesRecord storage rec = freezeLedger[member];
        require(rec.maxExpiryTs > 0,
            "No frozen amount");
        require(rec.maxExpiryTs <= block.timestamp,
            "Freeze in effect");
        withdraw(member, rec.totalAmount);
        removeRecord(rec);
        rec.logs.length = 0;
    }

    function removeRecord(FreezesRecord storage rec) private {
        rec.maxExpiryTs = 0;
        rec.totalAmount = 0;
    }

    function withdraw(address member, uint128 amount) private {
        bool withdrawalSuccess = token.transfer(member, amount);
        require(withdrawalSuccess,
            "Token exception");

        emit TokensUnfrozen(member, amount);
    }

    function listFrozenRecords(address member) public view returns(uint64[] memory expiryTimestamps, uint128[] memory amounts) {
        FreezeLog[] storage logs = freezeLedger[member].logs;

        uint64 size = uint64(logs.length);
        expiryTimestamps = new uint64[](size);
        amounts = new uint128[](size);

        if (size > 0) {
            for (uint64 i = 0; i < size; i++) {
                FreezeLog storage l = logs[i];
                expiryTimestamps[i] = l.expiryTimestamp;
                amounts[i] = l.amount;
            }
        }
    }

    function balanceOf(address member) public view returns(uint128) {
        return freezeLedger[member].totalAmount;
    }

    function getMaxExpiry(address member) public view returns(uint64) {
        return freezeLedger[member].maxExpiryTs;
    }

}
