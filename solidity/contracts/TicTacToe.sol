pragma solidity ^0.5.0;  /* 4.24 */


contract ERC20Interface {

   /// @return total amount of tokens
   function totalSupply() public view returns (uint256 );
   /// @param _owner The address from which the balance will be retrieved
   /// @return The balance
   function balanceOf(address _owner) public view returns (uint256);

   /// @notice send `_value` token to `_to` from `msg.sender`
   /// @param _to The address of the recipient
   /// @param _value The amount of token to be transferred
   /// @return Whether the transfer was successful or not
   function transfer(address _to, uint256 _value) public returns (bool success);

   /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
   /// @param _from The address of the sender
   /// @param _to The address of the recipient
   /// @param _value The amount of token to be transferred
   /// @return Whether the transfer was successful or not
   function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

   /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
   /// @param _spender The address of the account able to transfer the tokens
   /// @param _value The amount of wei to be approved for transfer
   /// @return Whether the approval was successful or not
   function approve(address _spender, uint256 _value) public returns (bool success);

   /// @param _owner The address of the account owning tokens
   /// @param _spender The address of the account able to transfer the tokens
   /// @return Amount of remaining tokens allowed to spent
   function allowance(address _owner, address _spender) public view returns (uint256 remaining);

   event Transfer(address indexed _from, address indexed _to, uint256 _value);
   event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}




contract Fields {
   //if someone wants to choose a field, we need to make sure that it isn't occupied yet
   // i describes the row, k the column

   uint8 [3][3] internal fields;
   bool internal endGame = true; // true means game has already ended (default Value is true)
   string internal winnerOfGame = "";

   function fieldChange (uint8 i, uint8 k, uint8 value) internal { //not sure if I used enum correctly here
       fields[i-1][k-1] = value;
   } //this function is called when sb. wants to choose a field

   function getFieldValue(uint8 i, uint8 k) view public returns (uint8) {
       return fields[i-1][k-1];
   }

   function getAllFieldValues() view public returns (uint256) {
       uint8 i;
       uint8 k;
       uint256 result=0;
       uint256 position=0;
       for (i=0; i<=2; i++) {
           for (k=0; k<=2; k++) {
               result = result + (fields[i][k] * (10**position));
               position++;
           }
       }

       return result;
   }


}

contract User is Fields {

   ERC20Interface internal HSLUToken;

   address internal PlayerA;
   address internal PlayerB;
   mapping (address => uint8) internal playerSymbol;

   uint8 internal playerDefined = 0;

   function DefineUsers() public {
       require(endGame == true);
       require(PlayerB == 0x0000000000000000000000000000000000000000);

       if (PlayerA == 0x0000000000000000000000000000000000000000) {
           PlayerA = msg.sender;
           playerSymbol[PlayerA] = 1;
           playerDefined = 1;
			// check if tranfer allowed by sender
			if(!(HSLUToken.allowance(msg.sender, address(this) ) > 0)) revert('Transfer not allowed!');
           //check if the transaction was received
			if(!HSLUToken.transferFrom(msg.sender, address(this), uint256(100000000000000000))) revert('Transfer aborded!');
           // init fields
           for (uint8 i=0; i<=2; i++) {
               for (uint8 k=0; k<=2; k++) {
                   fields[i][k] = 0;
               }
           }
       }
       else if (PlayerA != msg.sender) {
           PlayerB = msg.sender;
           playerSymbol[PlayerB] = 2;
           playerDefined = 2;
           endGame = false;
			// check if tranfer allowed by sender
			if(!(HSLUToken.allowance(msg.sender, address(this)) > 0)) revert('Transfer not allowed!');
			//check if the transaction was received
           if(!HSLUToken.transferFrom(msg.sender, address(this), uint256(100000000000000000))) revert('Transfer aborded!');
       }
		// revert will abord the function

   }

//needs a lock, so functions can't be called while game is still going on

   function getPlayerA() view public returns (address) {
       return PlayerA;
   }

   function getPlayerB() view public returns (address) {
       return PlayerB;
   }

}



/*   k=1 k=2 k=3
    ___________  Plan
i=1 |___|___|___|
i=2 |___|___|___|
i=3 |___|___|___|
*/

contract Winner is User {

   uint count = 0;
   uint8 internal helpWinner = 0; //recognizing Winner

   function wonGameColumnk (uint playerValue, uint column) internal returns (bool) {
//column k
       count = 0;
       for (uint8 i=1; i<=3; i++) {
           if (fields[i-1][column-1] == playerValue) {
               count++;
           }
       }

       if (count == 3) {
           return true;
       }
       else {
           return false;
       }
   }



   function wonGameRowi (uint playerValue, uint row) internal returns (bool) {
//row i
       count = 0;
       for (uint8 k=1; k<=3; k++) {
           if (fields[row-1][k-1] == playerValue) {
               count++;
           }
       }

       if (count == 3) {
           return true;
       }
       else {
           return false;
       }
   }


   function wonGameDiagonal (uint8 playerValue) internal returns (bool) {
//bottom left to top right
       count = 0;
       uint8 i = 3;
       uint8 k = 0;
       for (k=0; k<=2; k++) {
           i = i - 1;
           if (fields[i][k] == playerValue) {
               count++;
           }
       }

       if (count == 3) {
           return true;
       }


//top left to bottom right
       count = 0;
       i = 0;
       for ( k=0; k<=2; k++) {
           if (fields[i][k] == playerValue) {
               count++;
           }
           i++;
       }

       if (count == 3) {
           return true;
       }
       else {
           return false;
       }
   }
}



contract playGame is Winner {

   uint8 internal whichPlayer = 1;
   uint8 internal moveCount = 0;
   uint256 playTime = 0;


   event gameOver(
       address Winner,
       string message
   );

   event Error(string mistake); // is emitted if sb. won the gameOver

   function checkTime() public {
       if (!endGame && now > playTime + 10 minutes) {
           if (address(whichPlayer) == PlayerA) {
               winner(PlayerB);
           }
           if (address(whichPlayer) == PlayerB) {
               winner(PlayerA);
           }
       }
   }


	constructor(address _HSLUToken) public {
	        HSLUToken = ERC20Interface(_HSLUToken);
   }


   function statusInit()  view public returns (uint8) {
       return playerDefined;

   }

   function whoseTurn() view public returns (uint8) {
       if (whichPlayer == 1) {
           return 1;
       }
       else {
           return 2;
       }
   }

   function checkWinner () view public returns (uint8) {
       if (endGame) {
           return helpWinner;
       }
       else {
           return 0;
       }
   }

	function whoAmI() view public returns (uint8) {
       if (PlayerA == msg.sender) {
           return 1;
       }
       else if (PlayerB == msg.sender) {
           return 2;
       }
       else{
           return 0;
       }
   }

   function getTime() view public returns (uint256) {
       return playTime;
   }


   function Play(uint8 i, uint8 k) public {
       require(playerDefined == 2);
       uint8 playerValue = playerSymbol[msg.sender];

       if (whichPlayer == playerValue) {
           if (fields[i-1][k-1] == 0) {

               fieldChange (i, k, playerSymbol[msg.sender]);

               if (msg.sender == PlayerA) {
                   whichPlayer = 2;
               }
               else {
                   whichPlayer = 1;
               }

               moveCount ++;
               playTime = now;
               //PlayerB is allowed to play now
               //checking if PlayerA has won:
               if (wonGameColumnk(playerValue, k) == true) {
                   winner(msg.sender);
               }
               if (wonGameRowi(playerValue, i) == true) {
                   winner(msg.sender);
               }
               if (wonGameDiagonal(playerValue) == true) {
                   winner(msg.sender);
               }
               if (moveCount == 9) {
                   winnerNobody();
               }
           }
           else {
               emit Error("field is already occupied");
           }
       }

       else {
           emit Error("it's not your turn yet");
       }

   } //function which is called by PlayerA to choose field i,k



   function reset() internal {
       endGame = true;
       playerDefined = 0;
       PlayerA = 0x0000000000000000000000000000000000000000;
       PlayerB = 0x0000000000000000000000000000000000000000;
       whichPlayer = 1;
       moveCount = 0;
   }

   function winner(address checkWinnerId) internal {
       emit gameOver(checkWinnerId, "has won the Game");

		if(!HSLUToken.transfer(checkWinnerId, uint256(200000000000000000))) revert();

       if (checkWinnerId == PlayerA) {
           helpWinner = 1;
       }

       else {
           helpWinner = 2;
       }
       reset();

   }


   function winnerNobody() internal {
       helpWinner = 3;
		if(!HSLUToken.transfer(PlayerA, uint256(100000000000000000))) revert();
		if(!HSLUToken.transfer(PlayerB, uint256(100000000000000000))) revert();

       reset();
   }

}
