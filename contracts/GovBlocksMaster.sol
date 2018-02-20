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


pragma solidity ^0.4.8;
import "./Master.sol";

contract GovBlocksMaster 
{
    
    Master MS;
    address public owner;
  
    struct govBlocksUsers
    {
      string GbUserName;
      address masterAddress;
    }
    address GBTControllerAddress;
    address GBTAddress;

    mapping(bytes32=>address) govBlocksDapps;
    bytes32[] allGovBlocksUsers;


    function GovBlocksMasterInit(address _GBTControllerAddress,address _GBTAddress) 
    {
      require(owner == 0x00);
      owner = msg.sender; 
      GBTControllerAddress=_GBTControllerAddress;
      GBTAddress = _GBTAddress;
      
    } 
    
    modifier onlyOwner() 
    {
      require(msg.sender == owner);
      _;
    }

    function transferOwnership(address _newOwner) onlyOwner  
    {
      owner = _newOwner;
    }

    function updateGBTAddress(address _GBTContractAddress) onlyOwner
    {
        GBTAddress=_GBTContractAddress;
        for(uint i=0;i<allGovBlocksUsers.length; i++){
        address masterAddress = govBlocksDapps[allGovBlocksUsers[i]];
        MS=Master(masterAddress);
        MS.changeGBTAddress(_GBTContractAddress);
        }
       
    }

     function updateGBTControllerAddress(address _GBTConrollerAddress) onlyOwner
    {
        GBTControllerAddress=_GBTConrollerAddress;
        for(uint i=0;i<allGovBlocksUsers.length; i++){
        address masterAddress = govBlocksDapps[allGovBlocksUsers[i]];
        MS=Master(masterAddress);
        MS.changeGBTControllerAddress(_GBTConrollerAddress);
        }
       
    }

    function setGovBlocksOwnerInMaster(uint _masterId) onlyOwner
    {
        address masterAddress = govBlocksDapps[allGovBlocksUsers[_masterId]];
        MS=Master(masterAddress);
        MS.GovBlocksOwner();
    }

    address public _proposalCategoryAddress,_newMemberRoleAddress;
    function addGovBlocksUser(bytes32 _gbUserName) onlyOwner
    {
        require(govBlocksDapps[_gbUserName]==0x00);
         address _newMasterAddress = new Master();
        allGovBlocksUsers.push(_gbUserName);  
        govBlocksDapps[_gbUserName] = _newMasterAddress;
        // address _newMemberRoleAddress = new MemberRoles();
        // _proposalCategoryAddress = new ProposalCategory();
        MS=Master(_newMasterAddress);

        // MS.addNewVersion([address(0),_newMemberRoleAddress,_proposalCategoryAddress,address(0),address(0),address(0),address(0),address(0),address(0),GBTControllerAddress,GBTAddress]);
        // MS.switchToRecentVersion();
        // MS.changeOtherAddress();

    }
    

    function changeDappMasterAddress(bytes32 _gbUserName,address _newMasterAddress)
    {
     if( govBlocksDapps[_gbUserName] == 0x000)
                 govBlocksDapps[_gbUserName] = _newMasterAddress;
     else
      {            
                if(msg.sender ==  govBlocksDapps[_gbUserName])
                     govBlocksDapps[_gbUserName] = _newMasterAddress;
                else
                    throw;
      }   
    }

    function getGovBlocksUserDetails(bytes32 _gbUserName) constant returns(bytes32 GbUserName,address MasterContractAddress)
    {
        return (_gbUserName,govBlocksDapps[_gbUserName]);
    }
     function getGovBlocksUserDetailsByIndex(uint _index) constant returns(uint index,bytes32 GbUserName,address MasterContractAddress)
    {
        return (_index,allGovBlocksUsers[_index],govBlocksDapps[allGovBlocksUsers[_index]]);
    }

}