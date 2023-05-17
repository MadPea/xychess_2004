///////////////////////////////////////////////////////////////////////////////////////////
// Board Square Script
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
// Color enumeration (NON-STANDARD.. Index-based).
integer WHITE           = 0;
integer BLACK           = 1;

// Update pin id.
integer PIN_ID          = 2923340592;

// Which face the 'top' of the square is.
integer TOP_SIDE        = 0;

key TRANSPARENT = "701917a8-d614-471f-13dd-5f4644e36e3c";

// Channels to set up button activate texture.
integer SET_BUTTON_INFO_A   = 9000;
integer SET_BUTTON_INFO_B   = 9001;
integer REQUEST_BUTTON_INFO = 9002;
integer SET_VALID_TOUCHER   = 9003;

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

// Seperator to use instead of comma.
string  FIELD_SEPERATOR = "~!~";
///////////// END CONSTANTS ////////////////

///////////// GLOBAL VARIABLES ///////////////
// Colors to use.         // White,           Black
list    gClickedColors  = [ <1.0, 0.0, 0.0>, <1.0, 0.0, 0.0> ];
list    gSelectedColors = [ <1.0, 0.5, 0.0>, <1.0, 0.5, 0.0> ];
list    gValidColors    = [ <0.5, 1.0, 0.5>, <0.0, 0.5, 0.0> ];
list    gMovingColors   = [ <0.0, 1.0, 1.0>, <0.0, 1.0, 1.0> ];
list    gPromoteColors  = [ <1.0, 1.0, 0.0>, <1.0, 1.0, 0.0> ];
list    gActiveTextures = [ "cb513f74-9a36-2eb7-c095-64bbf25499b5",
                            "cb513f74-9a36-2eb7-c095-64bbf25499b5" ];
// How long to show moving piece squares.
float   gMovingDelay    = 0.5;
// Whether or not this square is selected.
integer gSelected;
// Whether or not this square is being processed because of a click.
integer gClicked;
// Whether or not this square is a valid move.
integer gIsValidMove    = FALSE;
// Whether or not a pawn is in the process of promoting on this square.
integer gPromoting;
// Which button this is.
integer gButton;
// Key of the valid toucher.
key     gValidToucher = NULL_KEY;
// Whether or not to show valid moves.
integer gShowValidMoves = FALSE;
// The request id for show valid moves.
integer gRequestID;
// Which color this square is.
integer gColor;
/////////// END GLOBAL VARIABLES ////////////

//////////// Utility functions //////////////
integer GetRow(integer index) {
    return index / 8;
}

integer GetCol(integer index) {
    return index % 8;
}

integer GetIndex(integer row, integer col) {
    return row * 8 + col;
}

vector GetClickColor() {
    return llList2Vector(gClickedColors, gColor);
}

vector GetSelectedColor() {
    return llList2Vector(gSelectedColors, gColor);
}

vector GetValidColor() {
    return llList2Vector(gValidColors, gColor);
}

vector GetMovingColor() {
    return llList2Vector(gMovingColors, gColor);
}

vector GetPromoteColor() {
    return llList2Vector(gPromoteColors, gColor);
}

key GetActiveTexture() {
    return llList2Key(gActiveTextures, gColor);
}

SetActive() {
    llSetTexture(GetActiveTexture(), TOP_SIDE);
}

SetInactive() {
    llSetTexture(TRANSPARENT, TOP_SIDE);
}
////////// End Utility functions /////////////

// Update the display based on our current flags.
UpdateDisplay() {
    // First, check if we are clicked and being considered by the game.
    if (gClicked) {
        llSetColor(GetClickColor(), TOP_SIDE);
        SetActive();
        return;
    }
    // Now see if this square is current selected.
    if (gSelected) {
        llSetColor(GetSelectedColor(), TOP_SIDE);
        SetActive();
        return;
    }
    // Check if this is a valid move, and we are showing valid moves.
    if (gIsValidMove && gShowValidMoves) {
        llSetColor(GetValidColor(), TOP_SIDE);
        SetActive();
        return;
    }
    // Finally, see if this square has a pawn in the process of promoting.
    if (gPromoting) {
        llSetColor(GetPromoteColor(), TOP_SIDE);
        SetActive();
        return;
    }

    // Otherwise show nothing.
    SetInactive();
}

default {
    state_entry() {
        // First set the pin, for future updates.
        llSetRemoteScriptAccessPin(PIN_ID);

        // Figure out which button we are.
        list Parsed = llParseString2List(llGetObjectName(), [" "], []);
        gButton = (integer) llList2String(Parsed, -1);

        // Figure out which color we are, based on button number.
        if ( (GetRow(gButton) + GetCol(gButton)) % 2 == 0 ) {
            // If row + col is even, this is a black square.
            gColor = BLACK;
        }
        else // row + col is odd, this is a white square.
            gColor = WHITE;

        // Request activation info.
        llMessageLinked(LINK_SET, REQUEST_BUTTON_INFO, "", "");

        UpdateDisplay();
    }

    touch_start(integer num_detected) {
        // Check for a valid toucher.
        integer i;
        for (i = 0; i < num_detected; i++) {
            if (llDetectedKey(i) == gValidToucher) {
                // Tell the interface about this touch.
                llMessageLinked(LINK_SET, SQUARE_TOUCHED,
                            (string) gButton, llDetectedKey(i));
                return;
            }
        }
    }

    link_message(integer sender, integer channel, string data, key id) {
        if (channel == SET_BUTTON_INFO_A) {
            list Parsed = llParseString2List(data, [FIELD_SEPERATOR], []);

            // Re-create the gActiveTextures list.  It will be completed
            // in SET_BUTTON_INFO_B.
            gActiveTextures = [id];

            // Don't bother saving this, just use the same alpha.
            llSetAlpha  ((float)       llList2String(Parsed, 0), ALL_SIDES);
            gShowValidMoves = (integer)llList2String(Parsed, 1);

            gClickedColors  = [(vector)llList2String(Parsed, 2),
                               (vector)llList2String(Parsed, 3) ];

            gSelectedColors = [(vector)llList2String(Parsed, 4),
                               (vector)llList2String(Parsed, 5) ];
            gMovingDelay    = (float)  llList2String(Parsed, 6);
            return;
        }
        if (channel == SET_BUTTON_INFO_B) {
            list Parsed = llParseString2List(data, [FIELD_SEPERATOR], []);

            // Completed gActiveTextures list from SET_BUTTON_INFO_A.
            gActiveTextures += [id];

            gValidColors    = [(vector)llList2String(Parsed, 0),
                               (vector)llList2String(Parsed, 1) ];

            gMovingColors   = [(vector)llList2String(Parsed, 2),
                               (vector)llList2String(Parsed, 3) ];

            gPromoteColors  = [(vector)llList2String(Parsed, 4),
                               (vector)llList2String(Parsed, 5) ];
            return;
        }
        if (channel == SET_VALID_TOUCHER) {
            gValidToucher = id;
            return;
        }
        if (channel == SHOW_VALID_MOVES) {
            // Reset the valid moves flag, and wait for
            // VALID_MOVE messages with the given request id.
            list Parsed = llCSV2List(data);

            // Ignore everything but the request id.
            gRequestID = (integer)  llList2String(Parsed, 0);

            gIsValidMove = FALSE;
            UpdateDisplay();
            return;
        }
        if (channel == VALID_MOVE) {
            // See if this square is a valid move.
            list Parsed = llCSV2List(data);

            // Check that this is a VALID_MOVE message in response
            // to the current request id.
            integer MsgRequestID = (integer) llList2String(Parsed, 0);

            if (MsgRequestID != gRequestID)
                // Ignore it.
                return;

            // Extract the valid move.
            integer ValidMove = (integer) llList2String(Parsed, 1);

            // See if this is now a valid move.
            if (ValidMove == gButton) {
                gIsValidMove = TRUE;
                UpdateDisplay();
            }
            return;
        }
        if (channel == BOARD_SELECTION) {
            // See if this square was selected.
            integer Selection = (integer) data;

            if (Selection == gButton) {
                gClicked = TRUE;
                UpdateDisplay();
            }
            return;
        }
        if (channel == ALLOW_INPUT) {
            // The game manager is done considering a click.
            if (gClicked) {
                gClicked = FALSE;
                UpdateDisplay();
            }
            return;
        }
        if (channel == SELECT_PIECE) {
            if (gClicked) {
                gClicked = FALSE;
                UpdateDisplay();
            }

            // See if this square's piece is now selected.
            integer Selection = (integer) data;

            if (Selection == gButton) {
                gSelected = TRUE;
                UpdateDisplay();
            }
            return;
        }
        if (channel == DESELECT_PIECE) {
            if (gClicked) {
                gClicked = FALSE;
                UpdateDisplay();
            }

            // See if this square's piece is now deselected.
            integer Selection = (integer) data;

            if (Selection == gButton) {
                gSelected = FALSE;
                UpdateDisplay();
            }
            return;
        }
        if (channel == MOVE_PIECE) {
            if (gClicked) {
                gClicked = FALSE;
                UpdateDisplay();
            }

            // Check start and end positions.
            list Parsed = llCSV2List(data);

            integer Start   = (integer) llList2String(Parsed, 0);
            integer End     = (integer) llList2String(Parsed, 1);

            if (Start == gButton || End == gButton) {
                // This square is involved in a piece movement.
                // Undo any selection.
                gSelected = FALSE;

                // Switch to the moving color, and hold it for a while.
                llSetColor(GetMovingColor(), TOP_SIDE);
                SetActive();

                // Wait for a bit.
                llSleep(gMovingDelay);

                UpdateDisplay();
            }
            return;
        }
    }
}
