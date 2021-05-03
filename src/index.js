'use strict'
const FlexContract = require('flex-contract');
const process = require('process');
const BigNumber = require('bignumber.js');

const IMPL_ADDRESS = '0x5555555555555555555555555555555555555555';
const OWNER_ADDRESS = '0x7d3455421bbc5ed534a83c88fd80387dc8271392';
const STAKING_PROXY_ADDRESS = '0xa26e80e7dea86279c6d778d702cc413e6cffa777';
const STAKING_CODE = require('@0x/contracts-staking/test/generated-artifacts/Staking.json').compilerOutput.evm.deployedBytecode.object;
const CALL_OPTS = {
    overrides: {
        [OWNER_ADDRESS]: { code: require('../build/DeployFix.output.json').deployedBytecode },
        [IMPL_ADDRESS]: { code: STAKING_CODE },
    },
};
(async () => {
    const fixer = new FlexContract(
        require('../build/DeployFix.output.json').abi,
        OWNER_ADDRESS,
        { providerURI: process.env.NODE_RPC },
    );

    const r = await fixer.deploy(
        STAKING_PROXY_ADDRESS,
        IMPL_ADDRESS,
    ).call(CALL_OPTS);
    const results = {
        gasUsed: parseInt(r.gasUsed),
        currentEpoch: parseInt(r.currentEpoch),
        poolInfos: Object.assign({},
            ...r.poolInfos.map(e => ({
                [new BigNumber(e.poolId).toString(10)]: {
                    operatorRewards: toUnits(e.operatorRewards),
                    membersReward: toUnits(e.membersReward),
                    feesCollected: toUnits(e.feesCollected),
                    weightedStake: toUnits(e.weightedStake),
                },
            })),
        ),
    };
    console.log(results);
})();

function toUnits(wei) {
    return new BigNumber(wei).div('1e18').toString(10);
}
