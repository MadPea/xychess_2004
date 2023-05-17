///////////////////////////////////////////////////////////////////////////////////////////
// Test For Check Script
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

// Color enumeration.
integer WHITE           = 8;
integer BLACK           = 16;

integer NONE            = -1;

// Rules checking messages.
integer CHECK_BASE      = 11000;
//integer CHECK_PAWN      = 11000;
//integer CHECK_KNIGHT    = 11001;
//integer CHECK_BISHOP    = 11002;
//integer CHECK_ROOK      = 11003;
//integer CHECK_QUEEN     = 11004;
//integer CHECK_KING      = 11005;
integer TEST_CHECK_SETUP  = 11006;
integer TEST_CHECK_RESULTS= 11098;
integer CHECK_RESULTS     = 11099;
integer TEST_CHECK_BASE   = 11100;

// Check channel bases.
integer CHECK_FOR_PAWNS_OR_KING     = 11200;
integer CHECK_FOR_ROOKS_OR_QUEEN    = 11300;
integer CHECK_FOR_BISHOPS_OR_QUEEN  = 11400;
integer CHECK_FOR_KNIGHTS           = 11500;
// Check return channel base.
integer CHECK_FOR_PIECE_RETURN      = 11600;

// How many check types we have.
integer NUM_CHECK_TYPES = 4;

// Special move types.
integer PAWN_DOUBLE_MOVE    = 1000;
integer CASTLE_KING_SIDE    = 1001;
integer CASTLE_QUEEN_SIDE   = 1002;
integer PAWN_RECRUIT        = 1003;
integer PAWN_EN_PASSANT     = 1004;
///////////// END CONSTANTS ////////////////

///////////// GLOBAL VARIABLES ///////////////
// Which check tester we are.
integer gTestID;
// Channel to respond to check tests.
integer gTestCheckChannel;
// Channel to listen for returns from piece checking.
integer gCheckForPieceReturn;

// Data sent by the game for checking.
integer gColor;
//integer gType;
integer gOriginalRow;
integer gOriginalCol;
//integer gWhiteCanCastleKingSide;
//integer gWhiteCanCastleQueenSide;
//integer gBlackCanCastleKingSide;
//integer gBlackCanCastleQueenSide;
//integer gPawnEnPassant;
list    gBoard;
list    gOriginalBoard;

// Used while testing.
integer gMoveToTest;
integer gSpecialMoveType;
integer gNumChecksLeft;
integer gInCheck;
integer gBusy;
list    gPendingMoves;
list    gPendingSpecialMoveTypes;
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

integer GetPieceByIndex(integer index) {
    // Check for invalid index.
    if (index == NONE)
        return NONE;

    return llList2Integer(gBoard, index);
}

integer GetPiece(integer row, integer col) {
    return GetPieceByIndex( GetIndex(row, col) );
}


integer GetEnemy(integer color) {
    if (color == WHITE)
        return BLACK;

    return WHITE;
}

////////// End Utility functions /////////////

ReadData(string data) {
    // Parse data into useful information.
    list Parsed = llCSV2List(data);
    gColor                  = (integer) llList2String(Parsed, 0);
    gOriginalRow            = (integer) llList2String(Parsed, 2);
    gOriginalCol            = (integer) llList2String(Parsed, 3);
    gOriginalBoard          =           llList2List  (Parsed, 9, -1);
}

MovePiece(integer start, integer end) {
    // Get the piece we are moving.
    integer Piece = GetPieceByIndex(start);
    // Set the start piece to NONE on the board.
    gBoard = llDeleteSubList(gBoard, start, start);
    gBoard = llListInsertList(gBoard, [NONE], start);
    // Replace the end piece with the start piece.
    gBoard = llDeleteSubList(gBoard, end, end);
    gBoard = llListInsertList(gBoard, [Piece], end);
}

RequestCheck(integer row, integer col, integer check_type) {
    // Send out the request.
    llMessageLinked(llGetLinkNumber(), check_type + gTestID, llList2CSV(
                    [gColor, row, col] + gBoard), "");
}

ProcessMove(integer move_to_test, integer special_move_type) {
    gBoard = gOriginalBoard;
    gMoveToTest = move_to_test;
    gSpecialMoveType = special_move_type;
    gNumChecksLeft = NUM_CHECK_TYPES;
    gInCheck = FALSE;

    // First, make the requested move.
    MovePiece( GetIndex(gOriginalRow, gOriginalCol), gMoveToTest );

    // Now find the king on the board.
    integer King = gColor | KING;
    llSay(0, llList2CSV(gBoard));
    llSay(0, (string) King);
    integer KingPos = llListFindList(gBoard, [(string)King]);
    integer Row     = GetRow(KingPos);
    integer Col     = GetCol(KingPos);

    llSay(0, llList2CSV([KingPos, Row, Col]));

    // Check for any piece that might be threatening the king.
    RequestCheck(Row, Col, CHECK_FOR_BISHOPS_OR_QUEEN);
    RequestCheck(Row, Col, CHECK_FOR_ROOKS_OR_QUEEN);
    RequestCheck(Row, Col, CHECK_FOR_PAWNS_OR_KING);
    RequestCheck(Row, Col, CHECK_FOR_KNIGHTS);
}

default {
    state_entry() {
        // Figure out which test checker we are.
        list Parsed = llParseString2List(llGetScriptName(), [" "], []);
        gTestID = (integer) llList2String(Parsed, -1);
        gTestCheckChannel = TEST_CHECK_BASE + gTestID;
        gCheckForPieceReturn = CHECK_FOR_PIECE_RETURN + gTestID;
    }

    link_message(integer sender, integer channel, string data, key id) {
        if (channel >= CHECK_BASE && channel <= TEST_CHECK_SETUP) {
            ReadData(data);
            return;
        }
        if (channel == gTestCheckChannel) {
            // Split up the data.
            list Parsed = llCSV2List(data);
            integer MoveToTest      = (integer) llList2String(Parsed, 0);
            integer SpecialMoveType = (integer) llList2String(Parsed, 1);

            // If we are still waiting on the checking routines,
            // save this move for later processing.
            if (gBusy) {
                gPendingMoves += MoveToTest;
                gPendingSpecialMoveTypes += SpecialMoveType;
                return;
            }

            // Use the data read from a CHECK test or TEST_CHECK_SETUP
            // to test for a possible check.
            gBusy = TRUE;
            ProcessMove(MoveToTest, SpecialMoveType);
            return;
        }
        if (channel == gCheckForPieceReturn) {
            // Check the results of the test.
            integer InCheck = (integer) data;

            // If this position was in check, set the global flag
            // to notify the parent script.
            if (InCheck)
                gInCheck = TRUE;

            // See if there are any more checks on the way back.
            gNumChecksLeft--;
            if (gNumChecksLeft == 0) {
                // Send back the results.
                llMessageLinked(LINK_SET, TEST_CHECK_RESULTS,
                                llList2CSV([gMoveToTest, gSpecialMoveType, InCheck]), "");

                // If there was a pending move to test, process it.
                if (llGetListLength(gPendingMoves) != 0) {
                    // Get the move.
                    integer MoveToTest      = llList2Integer(gPendingMoves, 0);
                    integer SpecialMoveType = llList2Integer(gPendingSpecialMoveTypes, 0);

                    // Remove these from the pending lists.
                    gPendingMoves       = llDeleteSubList(gPendingMoves, 0, 0);
                    gPendingSpecialMoveTypes = llDeleteSubList(
                                                    gPendingSpecialMoveTypes, 0, 0);

                    // Process it.
                    ProcessMove(MoveToTest, SpecialMoveType);
                }
                else {
                    // Otherwise we are done.
                    gBusy = FALSE;
                }
            }
            return;
        }
    }
}
