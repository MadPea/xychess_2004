///////////////////////////////////////////////////////////////////////////////////////////
// Chess Game Manager Script
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

// Special move types.
integer PAWN_DOUBLE_MOVE    = 1000;
integer CASTLE_KING_SIDE    = 1001;
integer CASTLE_QUEEN_SIDE   = 1002;
integer PAWN_RECRUIT        = 1003;
integer PAWN_EN_PASSANT     = 1004;

// Interface messages.
integer AVATAR_IN_CHAIR         = 8000;
integer SQUARE_TOUCHED          = 8001;
integer RECRUIT_PAWN            = 8012;
integer DONE_RECRUITING         = 8013;

// Game messages.
integer NEW_GAME                = 16000;
integer ALLOW_INPUT             = 16001;
integer BOARD_SELECTION         = 16002;
integer SET_TURN                = 16003;

// Move validation messages.
integer VALID_MOVE              = 17000;
integer SHOW_VALID_MOVES        = 17001;
integer CANCEL_SHOW_VALID_MOVES = 17002;
integer BOARD_UPDATE            = 17003;
integer CHECK_VALID_MOVES       = 17004;
integer GET_VALIDATION          = 17005;
integer RETURN_VALIDATION       = 17006;


// Piece Manager Messages
integer CLEAR_BOARD     = 13000;
integer SETUP_BOARD     = 13001;
integer ADD_PIECE       = 13002;
integer REMOVE_PIECE    = 13003;
integer MOVE_PIECE      = 13004;
integer KILL_PIECE      = 13005;
integer SELECT_PIECE    = 13006;
integer DESELECT_PIECE  = 13007;

// This is the seperator to use instead of comma.
string  FIELD_SEPERATOR = "~!~";
///////////// END CONSTANTS ////////////////

///////////// GLOBAL VARIABLES ///////////////
// This holds the board state.
list    gBoard;
// This is the board ID used with board validation.
integer gBoardID;
// This is the current check being processed.
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
// Who's turn it is.
integer gTurn;
// This is the current move we are testing.
integer gMoveToProcess;
// Pawn we asked about recruitment for.
integer gPieceToRecruit;
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

SetTurn(integer color) {
    gTurn = color;
    llMessageLinked(LINK_SET, SET_TURN, (string) color, "");
}

NextTurn() {
    if (gTurn == WHITE)
        SetTurn(BLACK);
    else
        SetTurn(WHITE);
}


UpdateBoard() {
    // This sends the current board state to the move validator.

    // First create a new board ID to make sure all move validation
    // processes are using the current board.
    gBoardID = GetNewID();

    // Send all board data.
    llMessageLinked(LINK_SET, BOARD_UPDATE, llList2CSV(
                    [ gBoardID,
                      gWhiteCanCastleKingSide, gWhiteCanCastleQueenSide,
                      gBlackCanCastleKingSide, gBlackCanCastleQueenSide,
                      gPawnEnPassant ] + gBoard), "");
}


// This puts the board in the initial state.
InitializeBoard() {
    // Set up the board.
    llMessageLinked(LINK_SET, SETUP_BOARD, "", "");

    // Initialize the board list.
    gBoard  = [ WHITE | ROOK, WHITE | KNIGHT, WHITE | BISHOP, WHITE | QUEEN,
                WHITE | KING, WHITE | BISHOP, WHITE | KNIGHT, WHITE | ROOK,
                WHITE | PAWN, WHITE | PAWN,   WHITE | PAWN,   WHITE | PAWN,
                WHITE | PAWN, WHITE | PAWN,   WHITE | PAWN,   WHITE | PAWN,
                NONE, NONE, NONE, NONE, NONE, NONE, NONE, NONE,
                NONE, NONE, NONE, NONE, NONE, NONE, NONE, NONE ];
    gBoard += [ NONE, NONE, NONE, NONE, NONE, NONE, NONE, NONE,
                NONE, NONE, NONE, NONE, NONE, NONE, NONE, NONE,
                BLACK | PAWN, BLACK | PAWN,   BLACK | PAWN,   BLACK | PAWN,
                BLACK | PAWN, BLACK | PAWN,   BLACK | PAWN,   BLACK | PAWN,
                BLACK | ROOK, BLACK | KNIGHT, BLACK | BISHOP, BLACK | QUEEN,
                BLACK | KING, BLACK | BISHOP, BLACK | KNIGHT, BLACK | ROOK   ];

    // Set misc states.
    gWhiteCanCastleKingSide = TRUE;
    gWhiteCanCastleQueenSide = TRUE;
    gBlackCanCastleKingSide = TRUE;
    gBlackCanCastleQueenSide = TRUE;
    gPawnEnPassant  = NONE;
}

KillPiece(integer index) {
    integer Piece = GetPieceByIndex(index);

    llMessageLinked(LINK_SET, KILL_PIECE, llDumpList2String(
                [index, GetColor(Piece)], FIELD_SEPERATOR), "");
    // Set this piece to NONE on the board.
    gBoard = llDeleteSubList(gBoard, index, index);
    gBoard = llListInsertList(gBoard, [NONE], index);
}

MovePiece(integer start, integer end) {
    // Tell the interface to move it.
    llMessageLinked(LINK_SET, MOVE_PIECE, llList2CSV([start, end]), "");

    // Get the piece we are moving.
    integer Piece = GetPieceByIndex(start);
    // Set the start piece to NONE on the board.
    gBoard = llDeleteSubList(gBoard, start, start);
    gBoard = llListInsertList(gBoard, [NONE], start);
    // Replace the end piece with the start piece.
    gBoard = llDeleteSubList(gBoard, end, end);
    gBoard = llListInsertList(gBoard, [Piece], end);
}

AllowInput() {
    llMessageLinked(LINK_SET, ALLOW_INPUT, "", "");
}

integer IsCurrentColor(integer index) {
    // Check that the given index is of the current turn's color.
    if (GetColor( GetPieceByIndex(index) ) == gTurn)
        return TRUE;
    else
        return FALSE;
}

integer GetNewID() {
    // Just create a random number.
    return llRound(llFrand(1.0) * 2000000000);
}

CheckValidMoves(integer selection) {
    // This tells the move validator to start checking for
    // all valid moves of the selected piece.

    // First create a new check id.
    gCheckID = GetNewID();
    llMessageLinked(llGetLinkNumber(), CHECK_VALID_MOVES, llList2CSV(
                    [ gBoardID, gCheckID, selection ]), "");

    // Have these moves show up on the board.
    llMessageLinked(LINK_SET, SHOW_VALID_MOVES, llList2CSV([gCheckID]), "");
}

//CancelCheckValidMoves() {
    // Tell the check validation scripts to stop processing the current check id.
//    llMessageLinked(LINK_SET, CANCEL_CHECK_VALID_MOVES, (string) gCheckID, "");
//}

SelectPiece(integer selection) {
    gSelected = selection;
    llMessageLinked(LINK_SET, SELECT_PIECE, (string) gSelected, "");
    // Tell the move validator to start considering possible moves.
    CheckValidMoves(selection);
}

DeSelect() {
    llMessageLinked(LINK_SET, DESELECT_PIECE, (string) gSelected, "");
    gSelected = NONE;
}

default {
    state_entry() {
        // Just wait for a game on startup.
        state WaitForGame;
    }
}

state WaitForGame {
    state_entry() {
        // No game, so clear the board.
        llMessageLinked(LINK_SET, CLEAR_BOARD, "", "");
    }

    link_message(integer sender, integer channel, string data, key id) {
        // Wait for a new game message.
        if (channel == NEW_GAME) {
            state NewGame;
        }
    }
}

state NewGame {
    state_entry() {
        // Initialize the game, then wait for a selection.
        InitializeBoard();
        // It is white's turn.
        SetTurn(WHITE);

        // Update the board.
        UpdateBoard();

        // Now wait for the user to select something.
        state WaitForSelection;
    }
}

state WaitForSelection {
    state_entry() {
        // Turn on input so we can get a selection.
        AllowInput();
        // Stop showing valid moves.
        llMessageLinked(LINK_SET, SHOW_VALID_MOVES, "", "");
    }

    link_message(integer sender, integer channel, string data, key id) {
        // We are waiting for a selection.
        if (channel == BOARD_SELECTION) {
            integer Selection = (integer) data;

            // See if this is a piece of the correct color.
            if (IsCurrentColor(Selection))  {
                // Select the piece.
                SelectPiece(Selection);
                // We now have a selected piece.
                state PieceSelected;
            }
            else {
                // Otherwise wait for a different selection.
                AllowInput();
            }
            return;
        }
        // We can always get a new game request.
        if (channel == NEW_GAME) {
            state NewGame;
            return;
        }
    }
}

state PieceSelected {
    state_entry() {
        // Turn on input so we can get the user's next action.
        AllowInput();
    }

    link_message(integer sender, integer channel, string data, key id) {
        // We are waiting for a selection.
        if (channel == BOARD_SELECTION) {
            integer Selection = (integer) data;

            // If this is the piece that is already selected, then
            // deselect it.
            if (Selection == gSelected) {
                // Tell the interface to deselect the piece.
                DeSelect();
                // Wait for a different selection.
                state WaitForSelection;
                return;
            }

            // If this is a different piece of the current color,
            // then deselect the old piece, and select this one instead.
            if (IsCurrentColor(Selection)) {
                // Deselect the old piece.
                DeSelect();
                // Select this piece instead.
                SelectPiece(Selection);
                // Wait for a different selection.
                AllowInput();
                return;
            }

            // Otherwise see if that move is valid.
            gMoveToProcess = Selection;
            state ProcessMove;

            return;
        }
        // We can always get a new game request.
        if (channel == NEW_GAME) {
            state NewGame;
            return;
        }
    }
}


state ProcessMove {
    state_entry () {
        // Ask/wait for the move validation scripts to allow or deny this move.
        llMessageLinked(llGetLinkNumber(), GET_VALIDATION, llList2CSV([gCheckID, gMoveToProcess]), "");
    }

    link_message(integer sender, integer channel, string data, key id) {
        if (channel == RETURN_VALIDATION) {
            // Parse the message.
            list Parsed = llCSV2List(data);

            // Make sure this is the request we were waiting for.
            integer CheckID = (integer) llList2String(Parsed, 0);

            if (CheckID != gCheckID) {
                // This shouldn't happen.
                AssertionFailed("CheckID ! = gCheckID");
                state PieceSelected;
                return;
            }

            // See if this move was valid.
            integer IsValidMove = (integer) llList2String(Parsed, 1);
            if (IsValidMove) {
                // This is valid, make the move.
                integer Piece = GetPieceByIndex(gMoveToProcess);

                if (Piece != NONE) {
                    KillPiece(gMoveToProcess);
                    // If killing a corner piece, disallow castling in that corner.
                    if (gMoveToProcess == GetIndex(0, 0))
                        gWhiteCanCastleQueenSide = FALSE;
                    else if (gMoveToProcess == GetIndex(0, 7))
                        gWhiteCanCastleKingSide = FALSE;
                    else if (gMoveToProcess == GetIndex(7, 0))
                        gBlackCanCastleQueenSide = FALSE;
                    else if (gMoveToProcess == GetIndex(7, 7))
                        gBlackCanCastleKingSide = FALSE;
                }

                // If this was the king, invalidate castling.
                integer PieceToMove = GetPieceByIndex(gSelected);
                if (PieceToMove == (WHITE | KING)) {
                    //llSay(0, "White King");
                    gWhiteCanCastleKingSide = FALSE;
                    gWhiteCanCastleQueenSide = FALSE;
                }
                else if (PieceToMove == (BLACK | KING)) {
                    //llSay(0, "Black King");
                    gBlackCanCastleKingSide = FALSE;
                    gBlackCanCastleQueenSide = FALSE;
                }

                // If this was a rook, invalidate castling in some cases.
                if (PieceToMove == (WHITE | ROOK)) {
                    if (gSelected == GetIndex(0, 0))
                        gWhiteCanCastleQueenSide = FALSE;
                    else if (gSelected == GetIndex(0, 7))
                        gWhiteCanCastleKingSide = FALSE;
                }
                else if (PieceToMove == (BLACK | ROOK)) {
                    if (gSelected == GetIndex(7, 0))
                        gBlackCanCastleQueenSide = FALSE;
                    else if (gSelected == GetIndex(7, 7))
                        gBlackCanCastleKingSide = FALSE;
                }

                MovePiece(gSelected, gMoveToProcess);

                // See if this was a special move.
                integer MoveType = (integer) llList2String(Parsed, 2);
                integer PawnDoubleMove = FALSE;
                // Most aren't special, so check for that first.
                if (MoveType != NONE) {
                    // This move is special.
                    if (MoveType == PAWN_DOUBLE_MOVE) {
                        // Set the pawn en passant to this position.
                        gPawnEnPassant = gMoveToProcess;
                        PawnDoubleMove = TRUE;
                    }
                    else if (MoveType == PAWN_EN_PASSANT) {
                        // This is a pawn en passant move.  Kill the
                        // pawn en passant piece.
                        KillPiece(gPawnEnPassant);
                    }
                    else if (MoveType == CASTLE_KING_SIDE) {
                        // Move the corresponding rook to the correct position.
                        if (gTurn == WHITE) {
                            MovePiece(GetIndex(0, 7), GetIndex(0, 5));
                        }
                        else
                            MovePiece(GetIndex(7, 7), GetIndex(7, 5));
                    }
                    else if (MoveType == CASTLE_QUEEN_SIDE) {
                        // Move the corresponding rook to the correct position.
                        if (gTurn == WHITE)
                            MovePiece(GetIndex(0, 0), GetIndex(0, 3));
                        else
                            MovePiece(GetIndex(7, 0), GetIndex(7, 3));
                    }
                    else if (MoveType == PAWN_RECRUIT) {
                        // This pawn needs to be recruited.
                        gPieceToRecruit = gMoveToProcess;

                        // Reset the pawn en passant (since we are leaving this function
                        // in a non-standard way.
                        if (!PawnDoubleMove)
                            gPawnEnPassant = NONE;

                        // Wait for the recruit pawn dialog to finish.
                        state RecruitPawn;
                    }
                }

                // Reset the pawn en passant.
                if (!PawnDoubleMove)
                    gPawnEnPassant = NONE;

                NextTurn();

                // Update the board.
                UpdateBoard();

                state WaitForSelection;
            }
            else { // Not valid move.
                // Go back to normal piece selection mode.
                state PieceSelected;
            }

            return;
        }
        // We can always get a new game request.
        if (channel == NEW_GAME) {
            state NewGame;
            return;
        }
    }
}

state RecruitPawn {
    state_entry() {
        // Tell the recruitment dialog to recruit this pawn.
        llMessageLinked(LINK_SET, RECRUIT_PAWN, llList2CSV([gPieceToRecruit, gTurn]), "");
    }

    link_message(integer sender, integer channel, string data, key id) {
        if (channel == DONE_RECRUITING) {
            // Recruit the pawn to the piece type.
            integer Type = (integer) data;

            integer OldPiece = GetPieceByIndex(gPieceToRecruit);

            // Replace the pawn with the new type.
            gBoard = llDeleteSubList(gBoard, gPieceToRecruit, gPieceToRecruit);
            gBoard = llListInsertList(gBoard, [GetColor(OldPiece) | Type], gPieceToRecruit);

            // Continue the game.
            NextTurn();

            // Update the board.
            UpdateBoard();

            state WaitForSelection;
            return;
        }
        // We can always get a new game request.
        if (channel == NEW_GAME) {
            state NewGame;
            return;
        }
    }
}
