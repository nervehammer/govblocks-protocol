/* Copyright (C) 2017 GovBlocks.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

/**
 * @title votingType interface for All Types of voting.
 */

pragma solidity ^0.4.8;
import "./simpleVoting.sol";
import "./RankBasedVoting.sol";
import "./FeatureWeighted.sol";
import "./ProposalCategory";
import "./governanceData.sol";
import "./VotingType.sol";
import "./Pool.sol";
import "./Master.sol";
import "./Governance.sol";
import "./memberRoles";
import "./GBTStandardToken.sol";


contract StandardVotingType
{
    address GBTSAddress;
    address public masterAddress;
    GBTStandardToken GBTS;
    Master MS;
    Pool P1;
    Governance GOV;
    memberRoles MR;
    ProposalCategory PC;
    governanceData  GD;
    simpleVoting SV;
    RankBasedVoting RB;
    FeatureWeighted FW;
    VotingType VT;

    modifier onlyInternal {
        require(MS.isInternal(msg.sender) == 1);
        _; 
    }

    /// @dev Changes master's contract address
    /// @param _masterContractAddress New master contract address
    function changeMasterAddress(address _masterContractAddress)
    {
        if(masterAddress == 0x000)
            masterAddress = _masterContractAddress;
        else
        {
            require(MS.isInternal(msg.sender) == 1);
                masterAddress = _masterContractAddress;
        }
        MS=Master(masterAddress);
    }

    modifier onlyMaster
    {
        require(msg.sender == masterAddress);
        _;
    }
    
    /// @dev Changes other contracts' addresses
    /// @param _SVaddress New simple voting contract address
    /// @param _RBaddress New rank based contract address
    /// @param _FWaddress New feature weighted contracts address
    // function changeOtherContractAddress(bytes4 _contractName) onlyInternal 
    // {
    //     SVAddress = _SVaddress;
    //     RBAddress = _RBaddress;
    //     FWAddress = _FWaddress;
    // }

    /// @dev Changes all contracts' addresses
    /// @param _GDcontractAddress  New governance data contract address
    /// @param _MRcontractAddress New member roles contract address
    /// @param _PCcontractAddress New proposal category contract address
    /// @param _governanceContractAddress New governance contract address
    /// @param _poolContractAddress New pool contract address
    // function changeAllContractsAddress(address _GDcontractAddress, address _MRcontractAddress, address _PCcontractAddress,address _governanceContractAddress,address _poolContractAddress) onlyInternal 
    // {
    //     GDAddress = _GDcontractAddress;
    //     MRAddress = _MRcontractAddress;
    //     PCAddress = _PCcontractAddress;
    //     G1Address = _governanceContractAddress;
    //     P1Address = _poolContractAddress;
    // }

    /// @dev Changes Global objects of the contracts || Uses latest version
    /// @param contractName Contract name 
    /// @param contractAddress Contract addresses
    function changeAddress(bytes4 contractName, address contractAddress){
        if(contractName == 'GD'){
            GD = governanceData(contractAddress);
        } else if(contractName == 'MR'){
            MR = memberRoles(contractAddress);
        } else if(contractName == 'PC'){
            PC = ProposalCategory(contractAddress);
        } else if(contractName == 'SV'){
            SV = simpleVoting(contractAddress);
        } else if(contractName == 'RB'){
            RB = RankBasedVoting(contractAddress);
        } else if(contractName == 'FW'){
            FW = FeatureWeighted(contractAddress);
        } else if(contractName == 'GOV'){
            GOV = Governance(contractAddress);
        } else if(contractName == 'PL'){
            P1 = Pool(contractAddress);
        }
    }

    /// @dev Changes GBT standard token address
    /// @param _GBTSAddress GBT standard token address
    function changeGBTSAddress(address _GBTSAddress) onlyMaster
    {
        GBTSAddress = _GBTSAddress;
    }

    /// @dev Sets vote value given by member
    /// @param _memberAddress Member address
    /// @param _proposalId Proposal id
    /// @param _memberStake Member stake
    /// @return finalVoteValue Final vote value
    function setVoteValue_givenByMember(address _memberAddress,uint _proposalId,uint _memberStake) onlyInternal returns (uint finalVoteValue)
    {
        GBTS=GBTStandardToken(GBTSAddress);
        uint tokensHeld = SafeMath.div((SafeMath.mul(SafeMath.mul(GBTS.balanceOf(_memberAddress),100),100)),GBTS.totalSupply());
        uint value= SafeMath.mul(Math.max256(_memberStake,GD.scalingWeight()),Math.max256(tokensHeld,GD.membershipScalingFactor()));
        finalVoteValue = SafeMath.mul(GD.getMemberReputation(_memberAddress),value);
    }  
    
    /// @dev Checks for options
    /// @param _proposalId Proposal id
    /// @param _memberAddress Member address
    /// @return check Check flag
    function checkForOption(uint _proposalId,address _memberAddress) internal constant returns(uint check)
    {
        for(uint i=0; i<GD.getTotalVerdictOptions(_proposalId); i++)
        {
            if(GD.getOptionAddressByProposalId(_memberAddress,i) == _memberAddress)
                check = 1;
            else 
                check = 0;
        }
    }

    /// @dev Adds verdict option in standard voting type
    /// @param _proposalId Proposal id
    /// @param _memberAddress Member address
    /// @param _solutionHash Solution hash
    /// @param _dateAdd Date proposal was added
    function addSolutionSVT(uint _proposalId,address _memberAddress,string _solutionHash,uint _dateAdd) onlyInternal
    {
        GBTS=GBTStandardToken(GBTSAddress);
        require(checkForOption(_proposalId,_memberAddress) == 0);

        uint currentVotingId;
        (,,currentVotingId,,,) = GD.getProposalDetailsById2(_proposalId);
        require(currentVotingId == 0 && GD.getProposalStatus(_proposalId) == 2 && GBTS.balanceOf(_memberAddress) != 0 && GD.getVoteId_againstMember(_memberAddress,_proposalId) == 0);
        GD.setTotalOptions(_proposalId); 
        GD.setOptionAddress(_proposalId,_memberAddress);    
    }

    /// @dev Closes Proposal Voting after All voting layers done with voting or Time out happens.
    /// @param _proposalId Proposal id
    function closeProposalVoteSVT(uint _proposalId) onlyInternal
    {   
        VT=VotingType(GD.getProposalVotingType(_proposalId)); 
        uint8 _mrSequence;uint _majorityVote;uint24 _closingTime; uint category;uint currentVotingId;
        (,category,currentVotingId,,,) = GD.getProposalDetailsById2(_proposalId); 
        uint8 totaloptions = GD.getTotalVerdictOptions(_proposalId);
        (_mrSequenceId,_majorityVote,_closingTime) = PC.getCategpryData2(category,currentVotingId)
        require(GOV.checkProposalVoteClosing(_proposalId,_mrSequenceId,_closingTime,_majorityVote)==1); //1
        

        
        

        max=0;  
        for(uint8 i = 0; i < verdictOptions; i++)
        {
            totalVotes = SafeMath.add(totalVotes,GD.getVoteValuebyOption_againstProposal(_proposalId,_roleId,i)); 
            if(GD.getVoteValuebyOption_againstProposal(_proposalId,_roleId,max) < GD.getVoteValuebyOption_againstProposal(_proposalId,_roleId,i))
            {  
                max = i; 
            }
        }
        
        verdictVal = GD.getVoteValuebyOption_againstProposal(_proposalId,_roleId,max);
        
        if(totalVotes != 0)
        {
            if(SafeMath.div(SafeMath.mul(verdictVal,100),totalVotes)>=_majorityVote)
                {   
                    currentVotingId = currentVotingId+1;
                    if(max > 0 )
                    {
                        if(currentVotingId < PC.getRoleSequencLength(GD.getProposalCategory(_proposalId)))
                        // if(currentVotingId < _roleSequenceLength)
                        {
                            GOV.updateProposalDetails(_proposalId,currentVotingId,max,0);
                            P1.closeProposalOraclise(_proposalId,_closingTime); 
                            GD.callOraclizeCallEvent(_proposalId,GD.getProposalDateUpd(_proposalId),PC.getClosingTimeAtIndex(GD.getProposalCategory(_proposalId),currentVotingId+1));
                        } 
                        else
                        {
                            GOV.updateProposalDetails(_proposalId,currentVotingId,max,max);
                            GD.changeProposalStatus(_proposalId,3);
                            VT.giveReward_afterFinalDecision(_proposalId);
                        }
                    }
                    else
                    {
                        GOV.updateProposalDetails(_proposalId,currentVotingId,max,max);
                        GD.changeProposalStatus(_proposalId,4);
                        VT.giveReward_afterFinalDecision(_proposalId);
                        GOV.changePendingProposalStart();
                    }      
                } 
                else
                {
                    GOV.updateProposalDetails(_proposalId,currentVotingId,max,max);
                    GD.changeProposalStatus(_proposalId,5);
                    GOV.changePendingProposalStart();
                } 
        }
        else
        {
            GOV.updateProposalDetails(_proposalId,currentVotingId,max,max);
            GD.changeProposalStatus(_proposalId,5);
            GOV.changePendingProposalStart();
        }
    }
}





