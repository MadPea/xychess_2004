///////////////////////////////////////////////////////////////////////////////////////////
// Clear Board Script
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
integer CLEAR_BOARD     = 13000;
///////////// END CONSTANTS ////////////////

///////////// GLOBAL VARIABLES ///////////////
key gOwner;
/////////// END GLOBAL VARIABLES ////////////

default {
    state_entry() {
        gOwner = llGetOwner();
        llListen(0, "", gOwner, "clear board");
    }

    on_rez(integer param) {
        // See if owner changed.
        if (gOwner != llGetOwner())
            llResetScript();
    }

    listen(integer channel, string name, key id, string mesg) {
        // Make sure the user is close enough.
        llSensor("", id, AGENT, 5.0, PI);
    }

    sensor(integer num_detected) {
        // User was close enough, clear tiles.
        llMessageLinked(LINK_SET, CLEAR_BOARD, "", "");
    }
}
