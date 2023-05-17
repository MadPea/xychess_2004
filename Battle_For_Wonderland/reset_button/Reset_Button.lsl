///////////////////////////////////////////////////////////////////////////////////////////
// Reset Button Script
//
// Copyright (c) 2004 Xylor Baysklef
// Modified by Gaius Tripsa for MadPea Productions, May 2023
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

// Interface messages.
integer AVATAR_IN_CHAIR         = 8000;

integer NONE            = -1;

// Game messages.
integer NEW_GAME                = 16000;
integer RESET_MAIN              = 13008;
///////////// END CONSTANTS ////////////////

///////////// GLOBAL VARIABLES ///////////////
// Dialog box info.
integer gDialogCallback = NONE;
integer gDialogChannel  = NONE;

// Keys of players.
key     gWhitePlayer;
key     gBlackPlayer;
/////////// END GLOBAL VARIABLES ////////////

GiveConfirmationDialogBox(key id) {
    // First remove the old callback.
    if (gDialogCallback != NONE)
        llListenRemove(gDialogCallback);

    // First start listening on a random channel for the
    // return from this dialog box.
    gDialogChannel  = llRound(llFrand(1.0) * 2000000000) + 1;
    gDialogCallback = llListen(gDialogChannel, "", "", "");

    string message = "* Clear: This will end any game in progress and derez all chess pieces\n" +
                     "* Set up: This will end any game in progress and set up chess pieces for a new game.";
    list buttons = [ "Clear", "Set up" ];

    // Give the dialog box.
    llDialog(id, message, buttons, gDialogChannel);
}

default {
    state_entry() {
    }

    touch_start(integer num_detected) {
        // Only process touches from owner or a player.
        key Toucher = llDetectedKey(0);
        if (Toucher != llGetOwner() &&
            Toucher != gWhitePlayer &&
            Toucher != gBlackPlayer)
            return;

        GiveConfirmationDialogBox(Toucher);
    }

    listen(integer channel, string name, key id, string mesg) {
        if (channel == gDialogChannel) {
            // Remove the timeout and the callback.
            llListenRemove(gDialogCallback);
            gDialogCallback = NONE;
            //llSetTimerEvent(0.0);

            if (mesg == "Clear") {
                llMessageLinked(LINK_SET, RESET_MAIN, "", "");
                return;
            }

            // If they confirmed, then make a new game.
            if (mesg == "Set up") {
                llMessageLinked(LINK_SET, NEW_GAME, "", "");
            }
        }
    }

    link_message(integer sender, integer channel, string data, key id) {
        if (channel == AVATAR_IN_CHAIR) {
            integer Color = (integer) data;

            if (Color == WHITE)
                gWhitePlayer = id;
            else
                gBlackPlayer = id;

            return;
        }
    }
}
