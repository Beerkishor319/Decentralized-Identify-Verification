// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Project {
    // Structure to store identity information
    struct Identity {
        string name;
        string email;
        uint256 creationTime;
        bool isVerified;
        address verifiedBy;
        mapping(string => string) credentials; // credential type => credential hash
        string[] credentialTypes; // array to track credential types
    }
    
    // Structure to store verifier information
    struct Verifier {
        string organization;
        bool isAuthorized;
        uint256 verificationCount;
    }
    
    // Mappings
    mapping(address => Identity) public identities;
    mapping(address => Verifier) public verifiers;
    mapping(address => bool) public hasIdentity;
    
    // Contract owner
    address public owner;
    
    // Events
    event IdentityCreated(address indexed user, string name, uint256 timestamp);
    event IdentityVerified(address indexed user, address indexed verifier, uint256 timestamp);
    event CredentialAdded(address indexed user, string credentialType, uint256 timestamp);
    event VerifierAuthorized(address indexed verifier, string organization, uint256 timestamp);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier onlyAuthorizedVerifier() {
        require(verifiers[msg.sender].isAuthorized, "Only authorized verifiers can perform this action");
        _;
    }
    
    modifier hasValidIdentity(address user) {
        require(hasIdentity[user], "User does not have an identity");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    // Core Function 1: Create Identity
    function createIdentity(string memory _name, string memory _email) public {
        require(!hasIdentity[msg.sender], "Identity already exists for this address");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_email).length > 0, "Email cannot be empty");
        
        Identity storage newIdentity = identities[msg.sender];
        newIdentity.name = _name;
        newIdentity.email = _email;
        newIdentity.creationTime = block.timestamp;
        newIdentity.isVerified = false;
        
        hasIdentity[msg.sender] = true;
        
        emit IdentityCreated(msg.sender, _name, block.timestamp);
    }
    
    // Core Function 2: Verify Identity
    function verifyIdentity(address _user) public onlyAuthorizedVerifier hasValidIdentity(_user) {
        require(!identities[_user].isVerified, "Identity is already verified");
        
        identities[_user].isVerified = true;
        identities[_user].verifiedBy = msg.sender;
        
        // Increment verifier's verification count
        verifiers[msg.sender].verificationCount++;
        
        emit IdentityVerified(_user, msg.sender, block.timestamp);
    }
    
    // Core Function 3: Add Credential
    function addCredential(string memory _credentialType, string memory _credentialHash) public hasValidIdentity(msg.sender) {
        require(bytes(_credentialType).length > 0, "Credential type cannot be empty");
        require(bytes(_credentialHash).length > 0, "Credential hash cannot be empty");
        
        Identity storage userIdentity = identities[msg.sender];
        
        // Check if credential type already exists
        bool exists = false;
        for (uint i = 0; i < userIdentity.credentialTypes.length; i++) {
            if (keccak256(bytes(userIdentity.credentialTypes[i])) == keccak256(bytes(_credentialType))) {
                exists = true;
                break;
            }
        }
        
        if (!exists) {
            userIdentity.credentialTypes.push(_credentialType);
        }
        
        userIdentity.credentials[_credentialType] = _credentialHash;
        
        emit CredentialAdded(msg.sender, _credentialType, block.timestamp);
    }
    
    // Additional Functions
    
    // Authorize a verifier (only owner)
    function authorizeVerifier(address _verifier, string memory _organization) public onlyOwner {
        require(_verifier != address(0), "Invalid verifier address");
        require(bytes(_organization).length > 0, "Organization name cannot be empty");
        
        verifiers[_verifier] = Verifier({
            organization: _organization,
            isAuthorized: true,
            verificationCount: 0
        });
        
        emit VerifierAuthorized(_verifier, _organization, block.timestamp);
    }
    
    // Revoke verifier authorization (only owner)
    function revokeVerifier(address _verifier) public onlyOwner {
        require(verifiers[_verifier].isAuthorized, "Verifier is not authorized");
        verifiers[_verifier].isAuthorized = false;
    }
    
    // Get user's identity information
    function getIdentityInfo(address _user) public view hasValidIdentity(_user) returns (
        string memory name,
        string memory email,
        uint256 creationTime,
        bool isVerified,
        address verifiedBy,
        string[] memory credentialTypes
    ) {
        Identity storage userIdentity = identities[_user];
        return (
            userIdentity.name,
            userIdentity.email,
            userIdentity.creationTime,
            userIdentity.isVerified,
            userIdentity.verifiedBy,
            userIdentity.credentialTypes
        );
    }
    
    // Get specific credential
    function getCredential(address _user, string memory _credentialType) public view hasValidIdentity(_user) returns (string memory) {
        return identities[_user].credentials[_credentialType];
    }
    
    // Check if user is verified
    function isUserVerified(address _user) public view returns (bool) {
        if (!hasIdentity[_user]) {
            return false;
        }
        return identities[_user].isVerified;
    }
    
    // Get verifier information
    function getVerifierInfo(address _verifier) public view returns (
        string memory organization,
        bool isAuthorized,
        uint256 verificationCount
    ) {
        Verifier memory verifier = verifiers[_verifier];
        return (verifier.organization, verifier.isAuthorized, verifier.verificationCount);
    }
}
