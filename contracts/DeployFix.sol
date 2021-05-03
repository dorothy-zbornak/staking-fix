pragma solidity ^0.8;

interface IStaking {
    struct PoolStats {
        uint256 feesCollected;
        uint256 weightedStake;
        uint256 membersStake;
    }
    struct StoredBalance {
        uint64 currentEpoch;
        uint96 currentEpochBalance;
        uint96 nextEpochBalance;
    }
    enum StakeStatus {
        UNDELEGATED,
        DELEGATED
    }
    function currentEpoch() external view returns (uint256);
    function endEpoch()
        external
        returns (uint256);
    function attachStakingContract(address _stakingContract) external;
    function computeRewardBalanceOfOperator(bytes32 poolId)
        external
        view
        returns (uint256 reward);
    function computeRewardBalanceOfDelegator(bytes32 poolId, address member)
        external
        view
        returns (uint256 reward);
    function finalizePool(bytes32 poolId)
        external
        returns (uint256 operatorReward, uint256 membersReward);
    function lastPoolId()
        external
        view
        returns (bytes32);
    function getStakingPoolStatsThisEpoch(bytes32 poolId)
        external
        view
        returns (PoolStats memory);
    function getGlobalStakeByStatus(StakeStatus stakeStatus)
        external
        view
        returns (StoredBalance memory balance);
}

struct PoolInfo {
    bytes32 poolId;
    uint256 operatorRewards;
    uint256 membersReward;
    uint256 feesCollected;
    uint256 weightedStake;
}

contract DeployFix {
    function deploy(
        IStaking staking,
        address impl
    )
        external
        returns (
            uint256 gasUsed,
            PoolInfo[] memory poolInfos,
            uint256 currentEpoch
        )
    {
        gasUsed = gasleft();
        staking.attachStakingContract(impl);
        poolInfos = _finalize(staking);
        gasUsed = gasUsed - gasleft();
        currentEpoch = staking.currentEpoch();
    }

    function deploy2(
        IStaking staking,
        address impl
    )
        external
        returns (
            uint256 gasUsed,
            PoolInfo[] memory poolInfos,
            uint256 currentEpoch
        )
    {
        gasUsed = gasleft();
        staking.attachStakingContract(impl);
        _finalize(staking);
        poolInfos = _finalize(staking);
        gasUsed = gasUsed - gasleft();
        currentEpoch = staking.currentEpoch();
    }

    function _finalize(IStaking staking)
        private
        returns (
            PoolInfo[] memory poolInfos
        )
    {
        uint256 maxPoolId = uint256(staking.lastPoolId());
        poolInfos = new PoolInfo[](maxPoolId);
        for (uint256 i = 0; i < maxPoolId; ++i) {
            poolInfos[i].poolId = bytes32(i + 1);
            IStaking.PoolStats memory stats = staking.getStakingPoolStatsThisEpoch(poolInfos[i].poolId);
            poolInfos[i].feesCollected = stats.feesCollected;
            poolInfos[i].weightedStake = stats.weightedStake;
        }
        staking.endEpoch();
        for (uint256 i = 0; i < maxPoolId; ++i) {
            (poolInfos[i].operatorRewards, poolInfos[i].membersReward) =
                staking.finalizePool(poolInfos[i].poolId);
        }
    }
}
