///////////////////////////////////////////////////////////////////////////////////////////
// Pawn Recruitment Dialog Script
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

// Piece names list.
list    PIECE_NAMES     = [ "Pawn", "Knight",
                            "Bishop", "Rook",
                            "Queen", "King" ];

// Interface messages.
integer AVATAR_IN_CHAIR         = 8000;

// Game messages.
integer NEW_GAME                = 16000;

// Dialog boxes.
integer DIALOG_RECRUIT_PAWN         = 12000;
integer DIALOG_RECRUIT_PAWN_DONE    = 12001;

integer NONE            = -1;

// How long to wait before giving another dialog box.
float   DIALOG_TIMEOUT  = 15.0;
///////////// END CONSTANTS ////////////////

///////////// GLOBAL VARIABLES ///////////////
// Dialog box info.
integer gDialogCallback = NONE;
integer gDialogChannel  = NONE;

// Game state info.
key gWhitePlayer    = NULL_KEY;
key gBlackPlayer    = NULL_KEY;
integer gTurn;
/////////// END GLOBAL VARIABLES ////////////

GiveRecruitmentDialogBox() {
    // First remove the old callback.
    if (gDialogCallback != NONE)
        llListenRemove(gDialogCallback);

    // Figure out the key of the player to give the dialog to.
    key Avatar = gWhitePlayer;
    if (gTurn == BLACK)
        Avatar = gBlackPlayer;

    // First start listening on a random channel for the
    // return from this dialog box.
    gDialogChannel  = llRound(llFrand(1.0) * 2000000000) + 1;
    gDialogCallback = llListen(gDialogChannel, "", "", "");

    // Give the dialog box.
    llDialog(Avatar, "Select a piece to recruit to:",
            ["Queen", "Rook", "Bishop", "Knight"], gDialogChannel);
}

default {
    state_entry() {
    }

    listen(integer channel, string name, key id, string mesg) {
        if (channel == gDialogChannel) {
            // Remove the timeout and the callback.
            llListenRemove(gDialogCallback);
            gDialogCallback = NONE;
            llSetTimerEvent(0.0);

            // Convert the answer into a piece type.
            integer Type = llListFindList(PIECE_NAMES, [mesg]);

            // Assert type.
            if (Type == NONE) {
                llSay(0, "PawnRecruitDialog - Assertion Failed");
                Type = QUEEN;
            }

            // Tell the interface which piece was selected.
            llMessageLinked(LINK_SET, DIALOG_RECRUIT_PAWN_DONE, (string) Type, "");
            return;
        }
    }

    link_message(integer sender, integer channel, string data, key id) {
        if (channel == DIALOG_RECRUIT_PAWN) {
            gTurn = (integer) data;
            // Ask the player what piece to recruit this pawn to.
            // Set the timeout for the dialog box.
            llSetTimerEvent(DIALOG_TIMEOUT);

            // Give the player the dialog box.
            GiveRecruitmentDialogBox();
            return;
        }
        if (channel == AVATAR_IN_CHAIR) {
            integer Color = (integer) data;

            if (Color == WHITE)
                gWhitePlayer = id;
            else
                gBlackPlayer = id;

            return;
        }
        if (channel == NEW_GAME) {
            // Remove any dialog box, if active.
            if (gDialogCallback != NONE) {
                llListenRemove(gDialogCallback);
                gDialogCallback = NONE;
                llSetTimerEvent(0.0);
            }
            return;
        }
    }

    timer() {
        // Dialog box timed out.  Give a new one.
        GiveRecruitmentDialogBox();
    }
}
