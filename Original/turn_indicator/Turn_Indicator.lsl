///////////////////////////////////////////////////////////////////////////////////////////
// Turn Indicator Script
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

// Which face to set.
integer FACE            = 0;

// Game messages.
integer SET_TURN                = 16003;
///////////// END CONSTANTS ////////////////

///////////// GLOBAL VARIABLES ///////////////
/////////// END GLOBAL VARIABLES ////////////

SetTurn(integer color) {
    // Point texture in the correct direction, depending on the player's color.
    if (color == WHITE)
        llRotateTexture(0, FACE);
    else // color == BLACK
        llRotateTexture(PI, FACE);
}

default {
    state_entry() {
        // Default to white.
        SetTurn(WHITE);
    }

    link_message(integer sender, integer channel, string data, key id) {
        if (channel == SET_TURN) {
            // Point at this player.
            integer Color = (integer) data;
            SetTurn(Color);
        }
    }
}
