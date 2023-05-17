///////////////////////////////////////////////////////////////////////////////////////////
// Chess Interface Script
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
// Color enumeration.
integer WHITE           = 8;
integer BLACK           = 16;

// Piece enumeration.
integer PAWN            = 0;
integer KNIGHT          = 1;
integer BISHOP          = 2;
integer ROOK            = 3;
integer QUEEN           = 4;
integer KING            = 5;

// Interface messages.
integer AVATAR_IN_CHAIR         = 8000;
integer SQUARE_TOUCHED          = 8001;

// Game messages.
integer NEW_GAME                = 16000;
integer ALLOW_INPUT             = 16001;
integer BOARD_SELECTION         = 16002;
integer SET_TURN                = 16003;

// Move validation messages.
integer VALID_MOVE              = 17000;
integer SHOW_VALID_MOVES        = 17001;
integer CANCEL_SHOW_VALID_MOVES = 17002;


// Piece Manager Messages
integer CLEAR_BOARD     = 13000;
integer SETUP_BOARD     = 13001;
integer ADD_PIECE       = 13002;
integer REMOVE_PIECE    = 13003;
integer MOVE_PIECE      = 13004;
integer KILL_PIECE      = 13005;
integer SELECT_PIECE    = 13006;
integer DESELECT_PIECE  = 13007;


// Channels to set up button info.
integer SET_BUTTON_INFO_A   = 9000;
integer SET_BUTTON_INFO_B   = 9001;
integer REQUEST_BUTTON_INFO = 9002;
integer SET_VALID_TOUCHER   = 9003;

//vector  ACTIVE_BUTTON_COLOR = <0.86667, 0.67451, 0.38431>;
vector  ACTIVE_BUTTON_COLOR = <1, 0, 0>;
vector  VALID_BUTTON_COLOR  = <0, 0, 1>;
float   ACTIVE_BUTTON_ALPHA = 1.0;
key     ACTIVE_TEXTURE      = "cb513f74-9a36-2eb7-c095-64bbf25499b5";

// Colors the board squares use:    WHITE           BLACK
list    SQUARE_ACTION_COLORS= [ <1.0, 0.0, 0.0>, <1.0, 0.0, 0.0>,   // Clicked Colors
                                <1.0, 1.0, 0.0>, <1.0, 1.0, 0.5>,   // Selected Colors
                                <0.5, 0.5, 1.0>, <0.0, 0.0, 1.0>,   // Valid Colors
                                <0.0, 1.0, 1.0>, <0.0, 1.0, 1.0>,   // Moving Colors
                                <1.0, 1.0, 1.0>, <1.0, 1.0, 1.0> ]; // Promote Colors

// How long to hold the moving color on a square while moving.
float   MOVING_DELAY        = 0.5;

// This is the seperator to use instead of comma.
string  FIELD_SEPERATOR = "~!~";

// Misc Constant
integer NONE    = -1;
///////////// END CONSTANTS ////////////////

///////////// GLOBAL VARIABLES ///////////////
// Whether or not input is locked.
integer gLocked   = FALSE;

// Who's turn it is.
integer gTurn     = NONE;

// Key of players.
key     gWhitePlayer;
key     gBlackPlayer;
/////////// END GLOBAL VARIABLES ////////////

SetButtonInfo() {
    llMessageLinked(LINK_SET, SET_BUTTON_INFO_A, llDumpList2String( [
                    ACTIVE_BUTTON_ALPHA, TRUE,
                    llList2Vector(SQUARE_ACTION_COLORS, 0),
                    llList2Vector(SQUARE_ACTION_COLORS, 1),
                    llList2Vector(SQUARE_ACTION_COLORS, 2),
                    llList2Vector(SQUARE_ACTION_COLORS, 3),
                    MOVING_DELAY ],
                    FIELD_SEPERATOR), ACTIVE_TEXTURE);
    llMessageLinked(LINK_SET, SET_BUTTON_INFO_B, llDumpList2String( [
                    llList2Vector(SQUARE_ACTION_COLORS, 4),
                    llList2Vector(SQUARE_ACTION_COLORS, 5),
                    llList2Vector(SQUARE_ACTION_COLORS, 6),
                    llList2Vector(SQUARE_ACTION_COLORS, 7),
                    llList2Vector(SQUARE_ACTION_COLORS, 8),
                    llList2Vector(SQUARE_ACTION_COLORS, 9) ],
                    FIELD_SEPERATOR), ACTIVE_TEXTURE);
}

integer GetIndex(integer row, integer col) {
    return row * 8 + col;
}

integer GetRow(integer index) {
    return index / 8;
}

integer GetCol(integer index) {
    return index % 8;
}

key GetCurrentPlayer() {
    if (gTurn == WHITE)
        return gWhitePlayer;

    if (gTurn == BLACK)
        return gBlackPlayer;

    return NULL_KEY;
}

DeactivateTouch() {
    llMessageLinked(LINK_SET, SET_VALID_TOUCHER, "", NULL_KEY);
    gLocked = TRUE;
}

ActivateTouch() {
    llMessageLinked(LINK_SET, SET_VALID_TOUCHER, "", GetCurrentPlayer());
    gLocked = FALSE;
}

default {
    state_entry() {
        // This only needs to be done once.
        SetButtonInfo();
    }

    link_message(integer sender, integer channel, string data, key id) {
        if (channel == AVATAR_IN_CHAIR) {
            integer Color = (integer) data;

            if (Color == WHITE)
                gWhitePlayer = id;
            else
                gBlackPlayer = id;

            // If we aren't locked, update the toucher's id.
            if (!gLocked)
                ActivateTouch();

            return;
        }
        if (channel == SET_TURN) {
            // Update who's turn it is.
            gTurn = (integer) data;

            // If we aren't locked, update the toucher's id.
            if (!gLocked)
                ActivateTouch();

            return;
        }
        if (channel == SQUARE_TOUCHED) {
            // Ignore this is we are locked.
            if (gLocked)
                return;

            // Double check that this is the current player.
            if (id != GetCurrentPlayer())
                return;

            // Notify the board this square was selected.
            llMessageLinked(LINK_SET, BOARD_SELECTION, data, "");

            // Lock the interface until the board processes this.
            DeactivateTouch();
            return;
        }
        if (channel == ALLOW_INPUT) {
            // Unlock the interface.
            ActivateTouch();
            return;
        }
    }
}
