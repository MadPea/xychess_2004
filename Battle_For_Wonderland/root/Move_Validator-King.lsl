///////////////////////////////////////////////////////////////////////////////////////////
// Move Validator (King) Script
//
// Copyright (c) 2004 Xylor Baysklef
//
// This file is part of XyChess.
//
// XyChess is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// XyChess is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with XyChess; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
///////////////////////////////////////////////////////////////////////////////////////////

/////////////// CONSTANTS ///////////////////
// Piece enumeration.
integer PAWN            = 0;
integer KNIGHT          = 1;
integer BISHOP          = 2;
integer ROOK            = 3;
integer QUEEN           = 4;
integer KING            = 5;

// The type this validator is concerned with.
integer THIS_TYPE       = KING;

// Color enumeration.
integer WHITE           = 8;
integer BLACK           = 16;

integer NONE            = -1;

// Move validation messages.
integer VALID_MOVE              = 17000;
integer SHOW_VALID_MOVES        = 17001;
integer CANCEL_SHOW_VALID_MOVES = 17002;
integer BOARD_UPDATE            = 17003;
integer CHECK_VALID_MOVES       = 17004;
integer GET_VALIDATION          = 17005;
integer RETURN_VALIDATION       = 17006;

// Rules checking messages.
integer CHECK_BASE      = 11000;
//integer CHECK_PAWN      = 11000;
//integer CHECK_KNIGHT    = 11001;
//integer CHECK_BISHOP    = 11002;
//integer CHECK_ROOK      = 11003;
//integer CHECK_QUEEN     = 11004;
//integer CHECK_KING      = 11005;
//integer TEST_CHECK_SETUP  = 11006;
integer TEST_CHECK_RESULTS= 11098;
integer CHECK_RESULTS     = 11099;
integer TEST_CHECK_BASE   = 11100;

integer TOTAL_CHECK_SCRIPTS = 1;

// Possible check results.
integer NO_RESULTS          = 0;
integer VALID               = 1;
integer INVALID             = 2;

// Special move types.
integer PAWN_DOUBLE_MOVE    = 1000;
integer CASTLE_KING_SIDE    = 1001;
integer CASTLE_QUEEN_SIDE   = 1002;
integer PAWN_RECRUIT        = 1003;
integer PAWN_EN_PASSANT     = 1004;
///////////// END CONSTANTS ////////////////

///////////// GLOBAL VARIABLES ///////////////
// The board setup.
list    gBoard;
// The ID of the current board.
integer gBoardID;
// The ID of the current check.
integer gCheckID;

// These flags are used for castling.
integer gWhiteCanCastleKingSide;
integer gWhiteCanCastleQueenSide;
integer gBlackCanCastleKingSide;
integer gBlackCanCastleQueenSide;
// This is the index of a valid pawn which
// can be kill via pawn en passant.
integer gPawnEnPassant;
// This is the selected piece.
integer gSelected = NONE;

// Used during checking.
integer gColor;
integer gEnemy;
integer gRecruitRank;

// How many checks have been sent out.
integer gNumChecks;
// Which check tester to use next.
integer gCheckTesterNum;
// List of possible moves this piece can make.
list    gPossibleMoves;
// Which index in the possible moves list we are at.
integer gPossibleMovesIndex;
// Actual valid moves with their move-types (post check-validations).
list    gValidMoves;
list    gValidTypes;
/////////// END GLOBAL VARIABLES ////////////


//////////// Utility functions //////////////
integer GetColor(integer piece) {
    if (piece == NONE)
        return NONE;

    return piece & 24;
}

integer GetType(integer piece) {
    if (piece == NONE)
        return NONE;

    return piece & 7;
}

integer GetRow(integer index) {
    return index / 8;
}

integer GetCol(integer index) {
    return index % 8;
}

integer GetIndex(integer row, integer col) {
    // Bounds check.
    if (row < 0 || row > 7 ||
        col < 0 || col > 7)
        return NONE;

    return row * 8 + col;
}

integer GetPiece(integer row, integer col) {
    return llList2Integer(gBoard, row * 8 + col);
}

integer GetPieceByIndex(integer index) {
    // Check for invalid index.
    if (index == NONE)
        return NONE;

    return llList2Integer(gBoard, index);
}

integer GetEnemy(integer color) {
    if (color == WHITE)
        return BLACK;

    return WHITE;
}

////////// End Utility functions /////////////

AssertionFailed(string assertion) {
    llSay(0, llGetScriptName() + ": Assertion Failed! (" + assertion + ")");
}

AddPossibleMove(integer move, integer special_type) {
    // Increment the number of checks sent out.
    gNumChecks++;

    // Send out the move for testing.
    //llMessageLinked(LINK_SET, TEST_CHECK_BASE + (gCheckTesterNum % TOTAL_CHECK_SCRIPTS),
    //                llList2CSV([gBoardID, gCheckID, move]), "");

    // Move to the next test checker.
    gCheckTesterNum++;
    // Add this move to the possible moves list.
    gPossibleMoves  += [move, special_type, NO_RESULTS];
    // Move to the next position in the possible moves index.
    gPossibleMovesIndex++;

    // TEMP
    // Just add these as valid, for now.
    gValidMoves += [move];
    gValidTypes += [special_type];
    // Let the board know about this valid move (in case show valid moves is active).
    llMessageLinked(LINK_SET, VALID_MOVE, llList2CSV([gCheckID, move]), "");
}


integer CheckMove(integer row, integer col) {
    integer Move = GetIndex(row, col);

    // Make sure this move is on the board.
    if (Move == NONE)
        return FALSE;

    integer Piece = GetPieceByIndex(Move);

    if (Piece == NONE) {
        AddPossibleMove(Move, NONE);
        return TRUE;
    }

    if (GetColor(Piece) == gEnemy) {
        AddPossibleMove(Move, NONE);
        return FALSE;
    }

    return FALSE;
}


CheckValidMoves() {
    // Reset the possible moves list, and valid moves list.
    gPossibleMoves      = [];
    gPossibleMovesIndex = 0;
    gValidMoves         = [];
    gValidTypes         = [];
    // Reset how many checks have been sent out.
    gNumChecks          = 0;
    // Reset the check tester script to use.
    gCheckTesterNum     = 0;


    gEnemy      = GetEnemy(gColor);
    integer Row = GetRow(gSelected);
    integer Col = GetCol(gSelected);

    // Check the 8 squares near the king.
    integer RowCheck;
    integer ColCheck;
    for (RowCheck = Row - 1; RowCheck <= Row + 1; RowCheck++)
        for (ColCheck = Col - 1; ColCheck <= Col + 1; ColCheck++)
            if (RowCheck != Row || ColCheck != Col)
                CheckMove(RowCheck, ColCheck);

    // Check for castling.
    if ( (gColor == WHITE && gWhiteCanCastleKingSide) ||
         (gColor == BLACK && gBlackCanCastleKingSide) ) {
        // See if the king can castle on the king side.
        if (GetPiece(Row, Col + 1) == NONE &&
            GetPiece(Row, Col + 2) == NONE) {
            // We can castle.
            integer Move = GetIndex(Row, Col + 2);
            AddPossibleMove(Move, CASTLE_KING_SIDE);
        }
    }
    if ( (gColor == WHITE && gWhiteCanCastleQueenSide) ||
         (gColor == BLACK && gBlackCanCastleQueenSide) ) {
        // See if the king can castle on the queen side.
        if (GetPiece(Row, Col - 1) == NONE &&
            GetPiece(Row, Col - 2) == NONE &&
            GetPiece(Row, Col - 3) == NONE) {
            // We can castle.
            integer Move = GetIndex(Row, Col - 2);
            AddPossibleMove(Move, CASTLE_QUEEN_SIDE);
        }
    }
}

default {
    state_entry() {
    }

    link_message(integer sender, integer channel, string data, key id) {
        if (channel == BOARD_UPDATE) {
            // Extract board info.
            list Parsed = llCSV2List(data);

            gBoardID                = (integer) llList2String(Parsed, 0);
            gWhiteCanCastleKingSide = (integer) llList2String(Parsed, 1);
            gWhiteCanCastleQueenSide= (integer) llList2String(Parsed, 2);
            gBlackCanCastleKingSide = (integer) llList2String(Parsed, 3);
            gBlackCanCastleQueenSide= (integer) llList2String(Parsed, 4);
            gPawnEnPassant          = (integer) llList2String(Parsed, 5);

            gBoard                  =           llList2List(Parsed, 6, -1);
            gSelected = NONE;
            return;
        }
        if (channel == GET_VALIDATION) {
            // Parse the message.
            list Parsed = llCSV2List(data);

            // Make sure we are or were working on this check id.
            integer CheckID = (integer) llList2String(Parsed, 0);

            if (CheckID != gCheckID)
                // Ignore this request.
                return;

            // Otherwise see if the selected move is valid.
            integer RequestedMove = (integer) llList2String(Parsed, 1);
            integer ValidMoveIndex = llListFindList(gValidMoves, [RequestedMove]);

            // See if the move was in the list of possible moves.
            integer IsValid;
            integer ValidType;
            if (ValidMoveIndex == NONE) {
                IsValid     = FALSE;
                ValidType   = NONE;
            }
            else {
                IsValid     = TRUE;
                ValidType   = llList2Integer(gValidTypes, ValidMoveIndex);
            }

            // Return our results.
            llMessageLinked(sender, RETURN_VALIDATION, llList2CSV([gCheckID, IsValid, ValidType]), "");
            return;
        }
        if (channel == CHECK_VALID_MOVES) {
            // Extract check info.
            list Parsed = llCSV2List(data);

            integer BoardID = (integer) llList2String(Parsed, 0);

            // Assert that the board id is the same.
            if (BoardID != gBoardID) {
                AssertionFailed("BoardID != gBoardID");
                return;
            }

            gSelected       = (integer) llList2String(Parsed, 2);

            // Examine the selected piece for type.
            integer Piece = GetPieceByIndex(gSelected);

            // Assert that this is actually a piece.
            if (Piece == NONE) {
                AssertionFailed("Piece == NONE");
                return;
            }

            integer Type = GetType(Piece);

            // See if we are responsible for checking valid moves.
            if (Type != THIS_TYPE) {
                // Ignore it.
                gCheckID = NONE;
                return;
            }

            // Otherwise start checking for valid moves.
            gCheckID        = (integer) llList2String(Parsed, 1);
            gColor          = GetColor(Piece);

            // Show all valid moves.
            //llMessageLinked(LINK_SET, SHOW_VALID_MOVES, llList2CSV([gCheckID]), "");
            CheckValidMoves();
            return;
        }
        if (channel == TEST_CHECK_RESULTS) {
            // Check the id to see if we are interested in this.
            // Split up the data.
            list Parsed = llCSV2List(data);
            integer CheckID     = (integer) llList2String(Parsed, 0);

            if (CheckID != gCheckID)
                // Ignore it.
                return;

            // See which possible move this is for.
            integer MoveIndex   = (integer) llList2String(Parsed, 1);
            // Get the results.
            integer Result      = (integer) llList2String(Parsed, 2);

            // Decrement how many checks we are waiting for.
            gNumChecks--;

            // Split up the data.
            //list Parsed = llCSV2List(data);
            //integer Move        = (integer) llList2String(Parsed, 0);
            //integer SpecialMove = (integer) llList2String(Parsed, 1);
            //integer InCheck     = (integer) llList2String(Parsed, 2);

            // If this doesn't put us in check, it is really a valid move.
            //if (!InCheck) {
            //    gValidMoves += Move;
            //    if (SpecialMove != NONE) {
            //        gSpecialMoves += Move;
            //        gSpecialTypes += SpecialMove;
            //    }
            //}

            // If there is nothing else to check, then we are done.  Send back results.
            //if (gNumChecks == 0)
            //    SendResults();
        }
    }
}
