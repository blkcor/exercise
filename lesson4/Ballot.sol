// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Ballot {
    struct Voter {
        uint weight; // 投票权重
        bool voted; // 是否已投票
        address delegate; // 委托人
        uint vote; // 投票的提案索引
    }

    struct Proposal {
        bytes32 name; // 提案名称
        uint voteCount; // 得票数
    }

    address public chairperson;
    mapping(address => Voter) public voters;
    Proposal[] public proposals;

    uint public startTime; // 投票开始时间
    uint public endTime; // 投票结束时间

    // 事件定义
    event VoterWeightSet(address indexed voter, uint weight);
    event RightToVoteGranted(address indexed voter);
    event Delegated(address indexed from, address indexed to);
    event Voted(address indexed voter, uint proposalID);

    // 修饰符：仅限chairperson调用
    modifier onlyChairperson() {
        require(
            msg.sender == chairperson,
            "Only chairperson can call this function."
        );
        _;
    }

    // 修饰符：仅在投票开始前调用
    modifier beforeVoting() {
        require(
            block.timestamp < startTime,
            "Operation not allowed after voting has started."
        );
        _;
    }

    constructor(
        bytes32[] memory proposalNames,
        uint _startTime,
        uint _endTime
    ) {
        require(_startTime < _endTime, "Start time must be before end time.");
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
        }

        startTime = _startTime;
        endTime = _endTime;
    }

    /**
     * @dev 允许chairperson为特定选民设置投票权重。
     * 只能在投票开始前调用。
     * @param voter 选民地址
     * @param weight 设置的投票权重
     */
    function setVoterWeight(
        address voter,
        uint weight
    ) external onlyChairperson beforeVoting {
        require(voter != address(0), "Invalid address.");
        require(!voters[voter].voted, "Voter has already voted.");

        voters[voter].weight = weight;

        emit VoterWeightSet(voter, weight);
    }

    /**
     * @dev 允许chairperson赋予选民投票权，默认权重为1。
     * 只能在投票开始前调用。
     * @param to 选民地址
     */
    function giveRightToVote(address to) external onlyChairperson beforeVoting {
        require(to != address(0), "Invalid address.");
        require(!voters[to].voted, "The voter already voted.");
        require(voters[to].weight == 0, "Voter already has the right to vote.");

        voters[to].weight = 1;

        emit RightToVoteGranted(to);
    }

    /**
     * @dev 允许选民将投票权委托给他人。
     * @param to 被委托人的地址
     */
    function delegate(address to) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote.");
        require(!sender.voted, "Already voted.");
        require(to != msg.sender, "Self-delegation is disallowed.");

        // 遍历委托链，确保没有循环委托
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;
            require(to != msg.sender, "Found loop in delegation.");
        }

        Voter storage delegate_ = voters[to];
        require(delegate_.weight > 0, "Delegate has no right to vote.");

        sender.voted = true;
        sender.delegate = to;

        if (delegate_.voted) {
            // 如果被委托人已投票，则直接增加对应提案的得票数
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // 如果被委托人尚未投票，则增加其权重
            delegate_.weight += sender.weight;
        }

        emit Delegated(msg.sender, to);
    }

    /**
     * @dev 允许选民对提案进行投票。
     * @param proposalID 要投票的提案索引
     */
    function vote(uint proposalID) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote.");
        require(!sender.voted, "Already voted.");
        require(block.timestamp >= startTime, "Voting has not started yet.");
        require(block.timestamp <= endTime, "Voting has already ended.");
        require(proposalID < proposals.length, "Invalid proposal ID.");

        sender.voted = true;
        sender.vote = proposalID;
        proposals[proposalID].voteCount += sender.weight;

        emit Voted(msg.sender, proposalID);
    }

    /**
     * @dev 返回得票最多的提案索引。
     */
    function winningProposal() public view returns (uint winningProposal_) {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    /**
     * @dev 返回得票最多的提案名称。
     */
    function winningName() public view returns (bytes32 winningName_) {
        winningName_ = proposals[winningProposal()].name;
    }
}
