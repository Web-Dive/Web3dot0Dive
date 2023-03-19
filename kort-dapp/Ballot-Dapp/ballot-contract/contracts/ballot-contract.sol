// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
contract BallotV3 {

    struct Voter {
        //Voter 타입은 투표자 상세 정보를 담고 있다.
        uint weight;
        bool voted;
        uint vote;
    }

    struct Proposal {
        //Proposal 타입은 제안의 상세 정보를 담고 있는데, 현재는 voteCount만을 가지고 있다.
        uint voteCount;
    }

    address chairperson;
    mapping(address => Voter) voters; //투표자 주소를 투표자 상세 정보로 매핑
    Proposal[] proposals;

    enum Phase {Init, Regs, Vote, Done} //투표의 여러 단계(0,1,2,3)을 나타내고, Init 단계로 상태가 초기화 된다.

    Phase public state = Phase.Init;


    //수정자 정의
    modifier validPhase(Phase reqPhase) {
        require(state == reqPhase);
        _;
    }

    //수정자 정의
    modifier onlyChair() {
        require(msg.sender == chairperson);
        _;
    }

    //스마트 컨트랙트를 배포할 때 co nstructor 함수를 호출한다.
    constructor (uint numProposals) {
        //constructor는 컨트랙트 배포자로서 의장을 설정한다.
        chairperson = msg.sender;
        voters[chairperson].weight = 2; //의장 가중치를 2로 설정
        for (uint prop = 0; prop < numProposals; prop ++) {
            proposals.push(Proposal(0));
        }
        state = Phase.Regs; //Regs 단계로 변경
    }  

    //단계를 변화시키는 함수, 오직 의장만이 실행 할 수 있다.
    function changeState(Phase x) onlyChair public {
       // if(msg.sender != chairperson) revert(); //의장이 아니면 되돌림, onlyChair 수정자로 대체
        //if(x < state) revert(); //상태가 순서대로 진행되지 않으면 되돌림, require문으로 대체
        require(x > state);
        state = x;
    }

    //함수 헤더에 validPhase 수정자 사용, onlyChair 수정자까지 두개
    function register(address voter) public validPhase(Phase.Regs) onlyChair {
        //if(msg.sender != chairperson || voters[voter].voted) revert();//if문을 사용한 명시적 검증
        require(!voters[voter].voted);
        voters[voter].weight = 1;
        //voters[voter].voted = false;
    }

    //함수 헤더에 validPhase 수정자 사용(의해 강제 된다.), 오직 투표 단계에서만 사용 가능한 함수
    function vote(uint toProposal) public validPhase(Phase.Vote) {
        Voter memory sender = voters[msg.sender];
        //if(sender.voted || toProposal >= proposals.length) revert(); => require로 대체
        require(!sender.voted);
        require(toProposal < proposals.length);
        sender.voted = true;
        sender.vote = toProposal;
        //HYPERLINK "http://sender.vote/"sender.vote = toProposal;
        proposals[toProposal].voteCount += sender.weight;
    }

    //일기용 함수, 체인에 Tx를 기록하지 않는다./원래는 체인에 기록되지 않는 view 함수
    function reqWinner() public validPhase(Phase.Done) view returns (uint winningProposal) {
        uint winningVoteCount = 0;
            for(uint prop = 0; prop < proposals.length; prop++) {
                if(proposals[prop].voteCount > winningVoteCount){
                    winningVoteCount = proposals[prop].voteCount;
                    winningProposal = prop;
                }
            }
            assert(winningVoteCount >= 3);
    }

}