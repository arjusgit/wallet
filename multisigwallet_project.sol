pragma solidity 0.7.5;
pragma abicoder v2;

contract Wallet {
    //como es una multisig wallet, lo primero que tenemos que hacer es crear un array de direcciones
    address[] public owners;
    //Esta multisig wallet precisa un LIMITE de direcciones que formaran parte de la wallet
    uint limit;
    
    //El paso siguiente es crear una estructura/template para realizar transferencias
    
    struct Transfer{
        uint amount;
        address payable receiver;
        uint approvals;
        bool hasBeenSent;
        uint id;
    }
    
    //Los Events, o eventos en Español, permiten el uso de las funciones de logging que proporciona de manera nativa la Ethereum Virtual Machine (EVM)
   // y que a su vez se pueden utilizar para retornar datos a nuestras dapps haciendo uso de JavaScript como handler de dichos eventos.
   //Cuando invocamos un evento, los argumentos pasados se almacenan en un registro especial de la transacción.
    
    event TransferRequestCreated(uint _id, uint _amount, address _sender, address _receiver);
    //approvals es necesario para contabilizar la cantidad de aprobaciones
    event ApprovalReceived(uint _id, uint _approvals, address _approver);
    event TransferApproved(uint _id);
    
    Transfer[] transferRequests;
    
    mapping(address => mapping(uint => bool)) approvals;
    
    //Should only allow people in the owners list to continue the execution.
    modifier onlyOwners(){
        bool isOwner = false;
        for(uint i=0; i<owners.length;i++){
            if(owners[i] == msg.sender){
                isOwner = true;
            }
        }
        require(isOwner == true);
        _;
        
    }
    
    //Should initialize the owners list and the limit (number of signatures required)
    constructor(address[] memory _owners, uint _limit) {
        owners = _owners;
        limit = _limit;
    }
    
    //Empty function
    function deposit() public payable {}
    
    //Create an instance of the Transfer struct and add it to the transferRequests array
    function createTransfer(uint _amount, address payable _receiver) public onlyOwners {
        emit TransferRequestCreated(transferRequests.length, _amount, msg.sender, _receiver);
        transferRequests.push(
            Transfer(amount_, _receiver, 0, false, transferRequests.length)
        );
    }
    
    //Set your approval for one of the transfer requests.
    //Need to update the Transfer object.
    //Need to update the mapping to record the approval for the msg.sender.
    //When the amount of approvals for a transfer has reached the limit, this function should send the transfer to the recipient.
    //An owner should not be able to vote twice.
    //An owner should not be able to vote on a tranfer request that has already been sent.
    function approve(uint _id) public onlyOwners {
        require(approvals[msg.sender][_id] == false);
        require(transferRequests[_id].hasBeenSent == false);
        
        approvals[msg.sender][_id] = true;
        transferRequests[_id].approvals++;
        
        emit ApprovalReceived(_id, transferRequests[_id].approvals, msg.sender);
        
        if(transferRequests[_id].approvals >= limit){
            transferRequests[_id].hasBeenSent = true;
            transferRequests[_id].receiver.transfer(transferRequests[_id].amount);
            emit TransferApproved(_id);
        }
    }
    
    //Should return all transfer requests
    function getTransferRequests() public view returns (Transfer[] memory){
        return transferRequests;
    }
 
 
}
