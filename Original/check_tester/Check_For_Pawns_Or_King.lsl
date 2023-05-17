///////////////////////////////////////////////////////////////////////////////////////////
// Check For Pawns Or King Script
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

// Check channel bases.
integer CHECK_FOR_PAWNS_OR_KING     = 11200;
integer CHECK_FOR_ROOKS_OR_QUEEN    = 11300;
integer CHECK_FOR_BISHOPS_OR_QUEEN  = 11400;
integer CHECK_FOR_KNIGHTS           = 11500;
// Check return channel base.
integer CHECK_FOR_PIECE_RETURN      = 11600;
///////////// END CONSTANTS ////////////////

///////////// GLOBAL VARIABLES ///////////////
// Which check tester we are.
integer gTestID;
// Channel to respond to check tests.
integer gTestCheckChannel;
// The position to check.
integer gColor;
list    gBoard;

// Information about the enemy.
integer gEnemyColor;
integer gEnemyKing;
integer gEnemyPawn;
integer gEnemyQueen;
integer gEnemyKnight;
integer gEnemyRook;
integer gEnemyBishop;

// Used while testing.
integer gRow;
integer gCol;
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


integer CheckForPawnsOrKing() {
    // Check the two squares in the positions the pawns
    // could threaten from.
    integer Direction = 1;
    if (gEnemyColor == WHITE)
        Direction = -1;

    integer Piece;
    Piece = GetPiece(gRow + Direction, gCol + 1);
    if (Piece == gEnemyPawn || Piece == gEnemyKing)
        return TRUE;

    Piece = GetPiece(gRow + Direction, gCol - 1);
    if (Piece == gEnemyPawn || Piece == gEnemyKing)
        return TRUE;

    // Check the 2 other diagonal square for the enemy king.
    if ( GetPiece(gRow - Direction, gCol + 1) == gEnemyKing)
        return TRUE;

    if ( GetPiece(gRow - Direction, gCol - 1) == gEnemyKing)
        return TRUE;

    return FALSE;
}

integer CheckForKing() {
    // Check the 4 squares nearby for the enemy king
    // (exclude the 4 the pawns or king function checked)
    if ( GetPiece(gRow + 1, gCol) == gEnemyKing)
        return TRUE;
    if ( GetPiece(gRow - 1, gCol) == gEnemyKing)
        return TRUE;
    if ( GetPiece(gRow, gCol + 1) == gEnemyKing)
        return TRUE;
    if ( GetPiece(gRow, gCol - 1) == gEnemyKing)
        return TRUE;

    return FALSE;
}

ReadData(string data) {
    // Parse data into useful information.
    list Parsed = llCSV2List(data);

    gColor                  = (integer) llList2String(Parsed, 0);
    gRow                    = (integer) llList2String(Parsed, 1);
    gCol                    = (integer) llList2String(Parsed, 2);
    gBoard                  =           llList2List  (Parsed, 3, -1);

    gEnemyColor = GetEnemy(gColor);
    gEnemyPawn  = gEnemyColor | PAWN;
    gEnemyRook  = gEnemyColor | ROOK;
    gEnemyKnight= gEnemyColor | KNIGHT;
    gEnemyBishop= gEnemyColor | BISHOP;
    gEnemyQueen = gEnemyColor | QUEEN;
    gEnemyKing  = gEnemyColor | KING;
}

default {
    state_entry() {
        // Figure out which test checker we are.
        list Parsed = llParseString2List(llGetScriptName(), [" "], []);
        gTestID = (integer) llList2String(Parsed, -1);
        gTestCheckChannel = CHECK_FOR_PAWNS_OR_KING + gTestID;
    }

    link_message(integer sender, integer channel, string data, key id) {
        if (channel == gTestCheckChannel) {
            // Retrieve the board position to check.
            ReadData(data);

            integer Result = FALSE;

            if (CheckForPawnsOrKing())
                Result = TRUE;
            else
                if (CheckForKing())
                    Result = TRUE;

            // Send back the results.
            llMessageLinked(llGetLinkNumber(), CHECK_FOR_PIECE_RETURN + gTestID,
                            (string) Result, "");
            return;
        }
    }
}
