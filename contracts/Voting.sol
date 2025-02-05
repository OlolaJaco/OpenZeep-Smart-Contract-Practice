// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Ballot {

    // Structure to store information about a voter
    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        address delegate; // person delegated to
        uint vote;   // index of the voted proposal
    }

    // Structure to store information about a proposal
    struct Proposal {
        bytes32 name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    address public chairperson; // address of the chairperson

    // Mapping to store voters' information
    mapping(address => Voter) public voters;

    // Array to store all proposals
    Proposal[] public proposals;

    // Constructor to initialize the contract with proposal names
    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender; // set the chairperson as the contract deployer
        voters[chairperson].weight = 1; // give chairperson the right to vote

        // For each provided proposal name, create a new proposal object and add it to the proposals array
        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    // Function to give a voter the right to vote
    function giveRightToVote(address voter) external {
        require(msg.sender == chairperson, "Only chairperson can give right to vote.");
        require(!voters[voter].voted, "The voter already voted.");
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    // Function to delegate your vote to another voter
    function delegate(address to) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "You have no right to vote");
        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation is disallowed.");

        // Forward the delegation as long as `to` also delegated
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // Prevent loops in delegation
            require(to != msg.sender, "Found loop in delegation.");
        }

        Voter storage delegate_ = voters[to];

        require(delegate_.weight >= 1);

        sender.voted = true;
        sender.delegate = to;

        if (delegate_.voted) {
            // If the delegate already voted, add to the number of votes
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // If the delegate did not vote yet, add to their weight
            delegate_.weight += sender.weight;
        }
    }

    // Function to cast a vote for a proposal
    function vote(uint proposal) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;

        // Increase the vote count of the proposal
        proposals[proposal].voteCount += sender.weight;
    }

    // Function to compute the winning proposal
    function winnerProposal() public view returns (uint winningProposal_) {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    // Function to get the name of the winning proposal
    function winnerName() external view returns (bytes32 winnerName_) {
        winnerName_ = proposals[winnerProposal()].name;
    }
}